#!/bin/bash
# Phase 4: Build + Retry Logic
# Usage: bash build.sh {project-name}

set -euo pipefail

WORKSPACE="/root/.openclaw/workspace"
LOGFILE="/root/.openclaw/logs/incubator.log"
PROJECT_NAME="${1:-}"

if [ -z "$PROJECT_NAME" ]; then
  echo "Usage: bash build.sh {project-name}"
  exit 1
fi

PROJECT_DIR="$WORKSPACE/projects/$PROJECT_NAME"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Project dir not found: $PROJECT_DIR" >> "$LOGFILE"
  exit 1
fi

cd "$PROJECT_DIR"

# Check vite base parameter
if ! grep -q "base:" vite.config.ts 2>/dev/null; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: vite.config.ts missing base parameter" >> "$LOGFILE"
  exit 1
fi

START_TIME=$(date +%s)

# First build attempt
if npm run build 2>>"$LOGFILE"; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] BUILD SUCCESS (attempt 1)" >> "$LOGFILE"
else
  # Retry 1: clear node_modules and reinstall
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] BUILD FAILED — retry 1/2: clearing node_modules" >> "$LOGFILE"
  rm -rf node_modules package-lock.json dist
  npm install 2>>"$LOGFILE"
  if npm run build 2>>"$LOGFILE"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BUILD SUCCESS (retry 1)" >> "$LOGFILE"
  else
    # Retry 2: show TS errors and exit
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BUILD FAILED — retry 2/2: checking TS errors" >> "$LOGFILE"
    npx tsc --noEmit 2>&1 | head -30 >> "$LOGFILE"
    exit 1
  fi
fi

# Timeout check (60min warn, 90min stop)
CURRENT_TIME=$(date +%s)
ELAPSED=$(( (CURRENT_TIME - START_TIME) / 60 ))
if [ "$ELAPSED" -gt 90 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] FATAL: Phase 4 exceeded 90 minutes" >> "$LOGFILE"
  exit 1
elif [ "$ELAPSED" -gt 60 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: Phase 4 running for ${ELAPSED} minutes (>60)" >> "$LOGFILE"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] BUILD COMPLETED in ${ELAPSED} minutes" >> "$LOGFILE"