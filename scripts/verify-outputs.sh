#!/bin/bash
# Verify Phase output files exist and have minimum size
# Usage: bash verify-outputs.sh {project-name} {filename} {min-bytes}

set -euo pipefail

WORKSPACE="/root/.openclaw/workspace"
LOGFILE="/root/.openclaw/logs/incubator.log"
PROJECT_NAME="${1:-}"
FILENAME="${2:-}"
MIN_BYTES="${3:-100}"

if [ -z "$PROJECT_NAME" ] || [ -z "$FILENAME" ]; then
  echo "Usage: bash verify-outputs.sh {project-name} {filename} {min-bytes}"
  exit 1
fi

PROJECT_DIR="$WORKSPACE/projects/$PROJECT_NAME"
FILEPATH="$PROJECT_DIR/$FILENAME"

if [ ! -f "$FILEPATH" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $FILENAME missing (path: $FILEPATH)" >> "$LOGFILE"
  exit 1
fi

ACTUAL_SIZE=$(stat -c%s "$FILEPATH" 2>/dev/null || echo 0)
if [ "$ACTUAL_SIZE" -lt "$MIN_BYTES" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $FILENAME too small ($ACTUAL_SIZE bytes, min $MIN_BYTES)" >> "$LOGFILE"
  exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] VERIFY OK: $FILENAME ($ACTUAL_SIZE bytes >= $MIN_BYTES min)" >> "$LOGFILE"