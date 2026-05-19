#!/bin/bash
# Phase 4: Deploy + HTTP Verification
# Usage: bash deploy.sh {project-name}

set -euo pipefail

WORKSPACE="/root/.openclaw/workspace"
LOGFILE="/root/.openclaw/logs/incubator.log"
PROJECT_NAME="${1:-}"

if [ -z "$PROJECT_NAME" ]; then
  echo "Usage: bash deploy.sh {project-name}"
  exit 1
fi

PROJECT_DIR="$WORKSPACE/projects/incubated/$PROJECT_NAME"

if [ ! -d "$PROJECT_DIR/dist" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: dist/ not found, did build succeed?" >> "$LOGFILE"
  exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Deploying $PROJECT_NAME" >> "$LOGFILE"

# Clean + recreate deploy directory
rm -rf "/usr/share/nginx/html/$PROJECT_NAME"
mkdir -p "/usr/share/nginx/html/$PROJECT_NAME/assets"

# Copy index.html FIRST (prevents 403)
cp "$PROJECT_DIR/dist/index.html" "/usr/share/nginx/html/$PROJECT_NAME/index.html"

# Copy assets
cp "$PROJECT_DIR/dist/assets/"* "/usr/share/nginx/html/$PROJECT_NAME/assets/" 2>/dev/null || true

# Verify: index.html must not contain /assets/ absolute paths
if grep -q 'src="/assets/' "$PROJECT_DIR/dist/index.html"; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: index.html has bad /assets/ path" >> "$LOGFILE"
  exit 1
fi

# HTTP verification with retry (max 2)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://openginko.tech/$PROJECT_NAME/" 2>/dev/null || echo "000")
RETRY=0
while [ "$HTTP_CODE" != "200" ] && [ "$RETRY" -lt 2 ]; do
  RETRY=$((RETRY + 1))
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Deploy check HTTP $HTTP_CODE, retry $RETRY/2..." >> "$LOGFILE"
  sleep 3
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://openginko.tech/$PROJECT_NAME/" 2>/dev/null || echo "000")
done

if [ "$HTTP_CODE" != "200" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Deploy failed, HTTP $HTTP_CODE" >> "$LOGFILE"
  exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEPLOY SUCCESS: HTTP 200" >> "$LOGFILE"

# Runtime verification: use puppeteer to check for JS errors
SCRIPT_DIR="$(dirname "$0")"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] VERIFY: Running puppeteer smoke test..." >> "$LOGFILE"
if node "$SCRIPT_DIR/verify-page.js" "https://openginko.tech/$PROJECT_NAME/" 2>&1 | tee -a "$LOGFILE"; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] VERIFY: Smoke test PASSED" >> "$LOGFILE"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Smoke test FAILED" >> "$LOGFILE"
  exit 1
fi

# Post-deploy: update showcase and log
SCRIPT_DIR="$(dirname "$0")"
"$SCRIPT_DIR/collect-showcase.sh" >> "$LOGFILE" 2>&1 || true
python3 "$WORKSPACE/showcase-app/scripts/generate-log-json.py" >> "$LOGFILE" 2>&1 || true

# Verify metadata.json was populated; auto-fix if still skeleton placeholder
META_FILE="$WORKSPACE/projects/incubated/$PROJECT_NAME/metadata.json"
if [ -f "$META_FILE" ]; then
  META_NAME=$(python3 -c "import json; d=json.load(open('$META_FILE')); print(d.get('name',''))")
  if [ "$META_NAME" = "project-name" ] || [ -z "$META_NAME" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: metadata.json not populated, auto-fixing from SPEC.md..." >> "$LOGFILE"
    SPEC_FILE="$WORKSPACE/projects/incubated/$PROJECT_NAME/SPEC.md"
    if [ -f "$SPEC_FILE" ]; then
      python3 - << 'PYEOF' >> "$LOGFILE" 2>&1
import json, re
proj = '$PROJECT_NAME'
spec = open('$SPEC_FILE').read()
tagline_match = re.search(r'一句话描述[：:]*\s*([^\n]+)', spec)
desc_match = re.search(r'目标用户[：:]*\s*([^\n]+)', spec)
meta = {'name': proj, 'tagline': '', 'description': '', 'techStack': ['React','TypeScript','Tailwind','Vite'], 'features': [], 'incubatedAt': '2026-05-19', 'screenshot': 'screenshot.png'}
if tagline_match:
    meta['tagline'] = tagline_match.group(1).strip()[:30]
if desc_match:
    meta['description'] = desc_match.group(1).strip()[:100]
json.dump(meta, open('$META_FILE','w'), ensure_ascii=False, indent=2)
print(f'metadata.json auto-fixed: tagline={meta["tagline"]}')
PYEOF
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] metadata.json auto-fixed from SPEC.md" >> "$LOGFILE"
      bash "$SCRIPT_DIR/generate-card-svg.sh" "$PROJECT_NAME" card 361 170 >> "$LOGFILE" 2>&1 || true
      bash "$SCRIPT_DIR/generate-card-svg.sh" "$PROJECT_NAME" modal 511 220 >> "$LOGFILE" 2>&1 || true
      "$SCRIPT_DIR/collect-showcase.sh" >> "$LOGFILE" 2>&1 || true
    fi
  fi
fi