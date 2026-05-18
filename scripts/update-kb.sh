#!/bin/bash
# Post-run: Mandatory KB.md Update (Knowledge Accumulation)
# Usage: bash update-kb.sh {project-name}

set -euo pipefail

KB_FILE="/root/.openclaw/workspace/skills/ai-project-incubator/KB.md"
LOGFILE="/root/.openclaw/logs/incubator.log"
TODAY=$(date '+%Y-%m-%d')

if [ ! -f "$KB_FILE" ]; then
  echo "# AI Incubator Knowledge Base" > "$KB_FILE"
  echo "" >> "$KB_FILE"
  echo "## 已知问题" >> "$KB_FILE"
  echo "" >> "$KB_FILE"
  echo "## 设计经验" >> "$KB_FILE"
  echo "" >> "$KB_FILE"
  echo "## 开发陷阱" >> "$KB_FILE"
  echo "" >> "$KB_FILE"
fi

# If today's entry already exists, skip
if grep -q "$TODAY" "$KB_FILE" 2>/dev/null; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] KB.md already updated today" >> "$LOGFILE"
  return 0
fi

# Append today's entry
echo "" >> "$KB_FILE"
echo "## Last update: $TODAY" >> "$KB_FILE"
echo "- $TODAY：孵化执行完成" >> "$KB_FILE"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] KB.md updated with today entry" >> "$LOGFILE"