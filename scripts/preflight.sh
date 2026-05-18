#!/bin/bash
# Phase 0: Pre-flight + Pause Check + Lock File + Capability Boundary Pre-scan
# Usage: bash preflight.sh {project-name}

set -euo pipefail

SCRIPT_DIR="/root/.openclaw/workspace/skills/ai-project-incubator/scripts"
SKILL_DIR="/root/.openclaw/workspace/skills/ai-project-incubator"
WORKSPACE="/root/.openclaw/workspace"
LOGFILE="/root/.openclaw/logs/incubator.log"
PROJECT_NAME="${1:-}"

if [ -z "$PROJECT_NAME" ]; then
  echo "Usage: bash preflight.sh {project-name}"
  exit 1
fi

PROJECT_DIR="$WORKSPACE/projects/$PROJECT_NAME"

# ============================================================
# 1. Pause Switch Check
# ============================================================
if [ -f /root/.openclaw/incubator.paused ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] INCUBATOR PAUSED — skipping this run" >> "$LOGFILE"
  exit 0
fi

# ============================================================
# 2. Lock File (prevent concurrent runs)
# ============================================================
LOCKFILE="/root/.openclaw/incubator.lock"
if [ -f "$LOCKFILE" ]; then
  LAST_PID=$(cat "$LOCKFILE" 2>/dev/null || echo "")
  if [ -n "$LAST_PID" ] && kill -0 "$LAST_PID" 2>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Previous incubator running (PID $LAST_PID), skipping" >> "$LOGFILE"
    exit 0
  fi
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stale lock removed" >> "$LOGFILE"
  rm -f "$LOCKFILE"
fi
echo $$ > "$LOCKFILE"
trap "rm -f '$LOCKFILE'" EXIT

# ============================================================
# 3. Environment Pre-check
# ============================================================
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Environment pre-check" >> "$LOGFILE"

if ! /usr/sbin/nginx -t 2>&1 | grep -q "syntax is ok"; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Nginx config invalid" >> "$LOGFILE"
  exit 1
fi

if [ ! -w /usr/share/nginx/html/ ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Nginx html dir not writable" >> "$LOGFILE"
  exit 1
fi

if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: SKILL.md missing" >> "$LOGFILE"
  exit 1
fi

if [ ! -d "$SKILL_DIR/skeleton" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: skeleton dir missing" >> "$LOGFILE"
fi

if [ ! -f "$SKILL_DIR/KB.md" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: KB.md missing, will be created" >> "$LOGFILE"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Environment check PASSED" >> "$LOGFILE"

# ============================================================
# 4. Capability Boundary Pre-scan
# Scans project directory BEFORE execution begins to catch violations early.
# This runs during Phase 0 to catch problems before any work is done.
# ============================================================
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Capability boundary pre-scan" >> "$LOGFILE"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Project dir not yet created, skipping pre-scan (normal for first run)" >> "$LOGFILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Phase 0 PREFLIGHT PASSED" >> "$LOGFILE"
  exit 0
fi

# Scan for paid API patterns
PAID_API_FOUND=""
if grep -rn "deepseek\|zhipu\|openai\|月額\|¥\|付费" "$PROJECT_DIR/src" 2>/dev/null | grep -v "^#" | grep -v "//.*"; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: Potential paid API call detected" >> "$LOGFILE"
  PAID_API_FOUND="YES"
fi

# Scan for system file modification attempts
if grep -rn "chmod\|chown\|/etc/\|/usr/lib/\|/var/lib/" "$PROJECT_DIR/src" 2>/dev/null | grep -v "^#" | grep -v "//.*chmod\|//.*chown"; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: System file modification detected — ABORT" >> "$LOGFILE"
  echo "孵化任务异常：$PROJECT_NAME，检测到禁止的系统文件修改操作" | send_to_wechat
  exit 1
fi

# Scan for nginx config modification
if grep -rn "nginx\|sites-enabled\|sites-available" "$PROJECT_DIR/src" 2>/dev/null | grep -v "^#"; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Nginx modification detected — ABORT" >> "$LOGFILE"
  echo "孵化任务异常：$PROJECT_NAME，检测到禁止的 Nginx 修改操作" | send_to_wechat
  exit 1
fi

if [ -n "$PAID_API_FOUND" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: Paid API detected, continuing but MUST confirm with user before production" >> "$LOGFILE"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Capability pre-scan PASSED" >> "$LOGFILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Phase 0 PREFLIGHT PASSED" >> "$LOGFILE"