#!/bin/bash
# collect-showcase.sh — 扫描 incubated/ 目录，生成 projects.json
# Usage: bash collect-showcase.sh

set -euo pipefail

WORKSPACE="/root/.openclaw/workspace"
INCUBATED="$WORKSPACE/projects/incubated"
OUTPUT="$WORKSPACE/showcase/projects.json"
OUTPUT_DIR="/usr/share/nginx/html/showcase"
SCREENSHOT_BASE="/showcase/screenshots"

mkdir -p "$(dirname "$OUTPUT")"

echo "[" > "$OUTPUT"

FIRST=true

if [ ! -d "$INCUBATED" ]; then
  echo "  { \"error\": \"No incubated directory found\" }" >> "$OUTPUT"
  echo "]" >> "$OUTPUT"
  echo "Done: $OUTPUT"
  exit 0
fi

for proj in "$INCUBATED"/*; do
  [ -d "$proj" ] || continue

  NAME=$(basename "$proj")
  META="$proj/metadata.json"

  # Read from metadata.json if exists
  if [ -f "$META" ]; then
    TAGLINE=$(python3 -c "import json; d=json.load(open('$META')); print(d.get('tagline', '$NAME'))" 2>/dev/null || echo "$NAME")
    DESCRIPTION=$(python3 -c "import json; d=json.load(open('$META')); print(d.get('description', ''))" 2>/dev/null || echo "")
    TECH=$(python3 -c "import json; d=json.load(open('$META')); print(','.join(d.get('techStack', ['React','TS'])))" 2>/dev/null || echo "React,TS")
    INCUBATED_AT=$(python3 -c "import json; d=json.load(open('$META')); print(d.get('incubatedAt', ''))" 2>/dev/null || echo "")
    SS_NAME=$(python3 -c "import json; d=json.load(open('$META')); print(d.get('screenshot', ''))" 2>/dev/null || echo "")
  else
    TAGLINE="$NAME"
    DESCRIPTION=""
    TECH="React,TS"
    INCUBATED_AT=$(date -d "@$(stat -c %Y "$proj" 2>/dev/null || echo 0)" '+%Y-%m-%d' 2>/dev/null || echo "")
    SS_NAME=""
  fi

  # Screenshot URL - use SVG card (-card for home, -modal for detail)
  if [ -f "$OUTPUT_DIR/cards/$NAME-card.svg" ]; then
    SCREENSHOT_URL="/showcase/cards/$NAME-card.svg"
  elif [ -f "/usr/share/nginx/html/showcase/cards/$NAME-card.svg" ]; then
    SCREENSHOT_URL="/showcase/cards/$NAME-card.svg"
  elif [ -f "/usr/share/nginx/html/showcase/cards/$NAME.svg" ]; then
    SCREENSHOT_URL="/showcase/cards/$NAME.svg"
  else
    SCREENSHOT_URL=""
  fi

  # HTTP check
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://openginko.tech/$NAME/" 2>/dev/null || echo "000")
  STATUS="offline"
  [ "$HTTP_CODE" = "200" ] && STATUS="online"

  # Output JSON entry
  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    echo "," >> "$OUTPUT"
  fi

  python3 << PYEOF >> "$OUTPUT"
import json

entry = {
    "name": "$NAME",
    "tagline": "${TAGLINE}",
    "description": "${DESCRIPTION}",
    "techStack": "${TECH}",
    "status": "${STATUS}",
    "url": "https://openginko.tech/${NAME}/",
    "screenshot": "${SCREENSHOT_URL}",
    "incubatedAt": "${INCUBATED_AT}"
}
print(json.dumps(entry, ensure_ascii=False, indent=2))
PYEOF

done

echo "]" >> "$OUTPUT"

# Copy to nginx
cp "$OUTPUT" /usr/share/nginx/html/showcase/projects.json

echo "Done: $OUTPUT"