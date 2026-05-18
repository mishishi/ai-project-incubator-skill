#!/bin/bash
# Post-deploy: Automated Quality Scoring
# Usage: bash auto-score.sh {project-name}

set -euo pipefail

WORKSPACE="/root/.openclaw/workspace"
LOGFILE="/root/.openclaw/logs/incubator.log"
PROJECT_NAME="${1:-}"

if [ -z "$PROJECT_NAME" ]; then
  echo "Usage: bash auto-score.sh {project-name}"
  exit 1
fi

PROJECT_DIR="$WORKSPACE/projects/$PROJECT_NAME"

echo "========== Day-N 交付评分（自动化）=========="

# 1. Functionality: count functional code lines
FUNC_LINES=$(grep -c "function\|useState\|onClick" "$PROJECT_DIR/src/" 2>/dev/null || echo 0)
if [ "$FUNC_LINES" -gt 20 ]; then
  echo "功能完整度: 3/3 ($FUNC_LINES 行代码)"
elif [ "$FUNC_LINES" -gt 5 ]; then
  echo "功能完整度: 1/3 ($FUNC_LINES 行)"
else
  echo "功能完整度: 0/3"
fi

# 2. Design consistency: count Literary Dark token references
DESIGN_REF=$(grep -c "#0F0F0E\|#E07A3A\|#E8E4DC\|#8A857A\|#33302A" "$PROJECT_DIR/src/" 2>/dev/null || echo 0)
if [ "$DESIGN_REF" -gt 10 ]; then
  echo "设计一致性: 3/3 ($DESIGN_REF 处 token)"
elif [ "$DESIGN_REF" -gt 3 ]; then
  echo "设计一致性: 1/3 ($DESIGN_REF 处)"
else
  echo "设计一致性: 0/3"
fi

# 3. Deployment stability: HTTP check
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://openginko.tech/$PROJECT_NAME/" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
  echo "部署稳定性: 3/3 (HTTP $HTTP_CODE)"
elif [ "$HTTP_CODE" -lt 400 ]; then
  echo "部署稳定性: 1/3 (HTTP $HTTP_CODE)"
else
  echo "部署稳定性: 0/3 (HTTP $HTTP_CODE)"
fi

# 4. Chinese localization: count Chinese characters
ZH_CHARS=$(grep -c '[\\u4e00-\\u9fa5]' "$PROJECT_DIR/src/" 2>/dev/null || echo 0)
if [ "$ZH_CHARS" -gt 5 ]; then
  echo "中文本地化: 3/3 ($ZH_CHARS 处)"
elif [ "$ZH_CHARS" -gt 2 ]; then
  echo "中文本地化: 1/3 ($ZH_CHARS 处)"
else
  echo "中文本地化: 0/3"
fi

# 5. Onboarding: check file exists
if [ -f "$PROJECT_DIR/src/OnboardingGuide.tsx" ]; then
  echo "新手指引: 3/3 (文件存在)"
else
  echo "新手指引: 0/3 (文件不存在)"
fi

echo "==========================================="