#!/bin/bash
# AI Project Incubator - Node Controller (验证型,非执行型)
# Usage: bash scripts/runner.sh {project-name} {phase} [action]
#
# 子 agent 负责所有创意工作(调研/设计/写代码)
# runner.sh 只做质量验证和部署执行
#
# phase + action 组合:
#   {project-name} incubate            - 一键孵化:verify → build → deploy(完整流程)
#   {project-name} setup              - 从 skeleton 创建项目(子 agent 调用一次)
#   {project-name} verify-phase1      - 验证 research.md ≥100字节
#   {project-name} verify-phase2      - 验证 design-system.md ≥200字节
#   {project-name} verify-phase3      - 验证 SPEC.md + PLAN.md ≥100字节
#   {project-name} build              - 执行 build(内含重试+超时)
#   {project-name} deploy             - 执行 deploy(内含 HTTP 验证)
#   {project-name} score              - 自动化质量评分
#   {project-name} notify {status}  - 发送通知(success/failure)

set -euo pipefail

SCRIPT_DIR="/root/.openclaw/workspace/skills/ai-project-incubator/scripts"
SKILL_DIR="/root/.openclaw/workspace/skills/ai-project-incubator"
WORKSPACE="/root/.openclaw/workspace"
LOGFILE="/root/.openclaw/logs/incubator.log"
PROJECT_NAME="${1:-}"
PHASE="${2:-}"
ACTION="${3:-}"

if [ -z "$PROJECT_NAME" ] || [ -z "$PHASE" ]; then
  echo "Usage: bash runner.sh {project-name} {phase} [action]"
  echo "Phases: setup, verify-phase1, verify-phase2, verify-phase3, build, deploy, score, notify"
  exit 1
fi

PROJECT_DIR="$WORKSPACE/projects/incubated/$PROJECT_NAME"
mkdir -p "$(dirname "$LOGFILE")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [runner] $1" >> "$LOGFILE"
}

# ============================================================
# Phase: incubate - 一键完整孵化流程
# ============================================================
incubate() {
  log "INCUBATE: Starting full incubation for $PROJECT_NAME"
  setup
  verify-phase1
  verify-phase2
  verify-phase3
  if ! build; then
    log "INCUBATE: BUILD FAILED for $PROJECT_NAME - aborting"
    exit 1
  fi
  if ! deploy; then
    log "INCUBATE: DEPLOY FAILED for $PROJECT_NAME"
    exit 1
  fi
  log "INCUBATE: Complete for $PROJECT_NAME"
}

# ============================================================
# Phase: setup - 从 skeleton 创建项目骨架
# ============================================================
setup() {
  log "SETUP: Creating project from skeleton"

  if [ -d "$PROJECT_DIR" ]; then
    log "Project dir already exists, skipping setup"
    return 0
  fi

  cp -r "$SKILL_DIR/skeleton" "$PROJECT_DIR"

  # 替换所有 {project-name} 占位符
  find "$PROJECT_DIR" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.json" -o -name "*.md" -o -name "*.html" \) -exec sed -i "s/{project-name}/$PROJECT_NAME/g" {} \;

  # vite.config.ts 单独处理
  sed -i "s|base: '/{project-name}/'|base: '/$PROJECT_NAME/'|g" "$PROJECT_DIR/vite.config.ts"

  log "SETUP: Project created at $PROJECT_DIR"
}

# ============================================================
# Phase: verify-phase1 - 验证研究阶段输出
# ============================================================
verify-phase1() {
  log "VERIFY-PHASE1: Checking research.md"

  local file="$PROJECT_DIR/research.md"
  if [ ! -f "$file" ]; then
    log "ERROR: research.md not found"
    exit 1
  fi

  local size=$(stat -c%s "$file" 2>/dev/null || echo 0)
  if [ "$size" -lt 100 ]; then
    log "ERROR: research.md too small ($size bytes < 100)"
    exit 1
  fi

  log "VERIFY-PHASE1: OK ($size bytes)"
}

# ============================================================
# Phase: verify-phase2 - 验证设计系统输出
# ============================================================
verify-phase2() {
  log "VERIFY-PHASE2: Checking design-system.md"

  local file="$PROJECT_DIR/design-system.md"
  if [ ! -f "$file" ]; then
    log "ERROR: design-system.md not found"
    exit 1
  fi

  local size=$(stat -c%s "$file" 2>/dev/null || echo 0)
  if [ "$size" -lt 200 ]; then
    log "ERROR: design-system.md too small ($size bytes < 200)"
    exit 1
  fi

  log "VERIFY-PHASE2: OK ($size bytes)"
}

# ============================================================
# Phase: verify-phase3 - 验证 SPEC + Plan 输出
# ============================================================
verify-phase3() {
  log "VERIFY-PHASE3: Checking SPEC.md and PLAN.md"

  for f in SPEC.md PLAN.md; do
    local file="$PROJECT_DIR/$f"
    if [ ! -f "$file" ]; then
      log "ERROR: $f not found"
      exit 1
    fi
    local size=$(stat -c%s "$file" 2>/dev/null || echo 0)
    if [ "$size" -lt 100 ]; then
      log "ERROR: $f too small ($size bytes < 100)"
      exit 1
    fi
    log "VERIFY-PHASE3: $f OK ($size bytes)"
  done

  log "VERIFY-PHASE3: All files OK"
}

# ============================================================
# Phase: build - 构建项目
# ============================================================
build() {
  log "BUILD: Starting build for $PROJECT_NAME"

  if [ ! -d "$PROJECT_DIR" ]; then
    log "ERROR: Project dir not found"
    exit 1
  fi

  cd "$PROJECT_DIR"

  # 检查 vite base 参数
  if ! grep -q "base:" vite.config.ts 2>/dev/null; then
    log "ERROR: vite.config.ts missing base parameter"
    exit 1
  fi

  START_TIME=$(date +%s)

  # 第一次 build
  if npm run build 2>>"$LOGFILE"; then
    log "BUILD: SUCCESS (attempt 1)"
  else
    # 重试 1
    log "BUILD: FAILED - retry 1/2"
    rm -rf node_modules package-lock.json
    npm install 2>>"$LOGFILE"
    if npm run build 2>>"$LOGFILE"; then
      log "BUILD: SUCCESS (retry 1)"
    else
      # 重试 2
      log "BUILD: FAILED - retry 2/2"
      npx tsc --noEmit 2>&1 | head -30 >> "$LOGFILE"
      exit 1
    fi
  fi

  ELAPSED=$(( ($(date +%s) - START_TIME) / 60 ))
  log "BUILD: Completed in ${ELAPSED} minutes"

  # 超时检查
  if [ "$ELAPSED" -gt 90 ]; then
    log "FATAL: Build exceeded 90 minutes"
    exit 1
  elif [ "$ELAPSED" -gt 60 ]; then
    log "WARN: Build exceeded 60 minutes"
  fi
}

# ============================================================
# Phase: deploy - 部署项目
# ============================================================
deploy() {
  log "DEPLOY: Starting deploy for $PROJECT_NAME"

  if [ ! -d "$PROJECT_DIR/dist" ]; then
    log "ERROR: dist/ not found"
    exit 1
  fi

  # 清理并创建目标目录
  rm -rf "/usr/share/nginx/html/$PROJECT_NAME"
  mkdir -p "/usr/share/nginx/html/$PROJECT_NAME/assets"

  # 先复制 index.html(防止 403)
  cp "$PROJECT_DIR/dist/index.html" "/usr/share/nginx/html/$PROJECT_NAME/index.html"

  # 复制资源文件
  cp "$PROJECT_DIR/dist/assets/"* "/usr/share/nginx/html/$PROJECT_NAME/assets/" 2>/dev/null || true

  # 检查资源路径
  if grep -q 'src="/assets/' "$PROJECT_DIR/dist/index.html"; then
    log "ERROR: index.html contains bad /assets/ path"
    exit 1
  fi

  # HTTP 验证(最多重试 2 次)
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://openginko.tech/$PROJECT_NAME/" 2>/dev/null || echo "000")
  RETRY=0
  while [ "$HTTP_CODE" != "200" ] && [ "$RETRY" -lt 2 ]; do
    RETRY=$((RETRY + 1))
    log "DEPLOY: HTTP $HTTP_CODE, retry $RETRY/2..."
    sleep 3
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://openginko.tech/$PROJECT_NAME/" 2>/dev/null || echo "000")
  done

  if [ "$HTTP_CODE" != "200" ]; then
    log "ERROR: Deploy failed, HTTP $HTTP_CODE"
    exit 1
  fi

  # Puppeteer 冒烟测试
  log "DEPLOY: Running smoke test..."
  if ! node "$SCRIPT_DIR/verify-page.js" "https://openginko.tech/$PROJECT_NAME/"; then
    log "ERROR: Smoke test failed (console errors detected)"
    exit 1
  fi

  log "DEPLOY: SUCCESS (HTTP 200 + smoke test passed) — https://openginko.tech/$PROJECT_NAME/"

  # Log production URL in machine-parseable format for subagent reporting
  echo "PRODUCTION_URL=https://openginko.tech/$PROJECT_NAME/" >> "$LOGFILE"

  # Move project to incubated/ directory for Showcase tracking
  mkdir -p "$WORKSPACE/projects/incubated"
  if [ -d "$PROJECT_DIR" ] && [ ! -d "$WORKSPACE/projects/incubated/$PROJECT_NAME" ]; then
    mv "$PROJECT_DIR" "$WORKSPACE/projects/incubated/$PROJECT_NAME"
    log "DEPLOY: Project moved to incubated/ for Showcase"
  fi

  # Generate SVG cards for Showcase
  # Card (home page): 361x170 - generated on deploy
  # Modal (popup): 511x220 - generated on deploy for best quality
  if bash "$SCRIPT_DIR/generate-card-svg.sh" "$PROJECT_NAME" card 361 170; then
    log "DEPLOY: Card SVG generated (361x170)"
  else
    log "WARN: Card SVG generation failed, continuing"
  fi
  if bash "$SCRIPT_DIR/generate-card-svg.sh" "$PROJECT_NAME" modal 511 220; then
    log "DEPLOY: Modal SVG generated (511x220)"
  else
    log "WARN: Modal SVG generation failed, continuing"
  fi
}

# ============================================================
# Phase: score - 自动化质量评分
# ============================================================
score() {
  log "SCORE: Running automated quality scoring"
  bash "$SCRIPT_DIR/auto-score.sh" "$PROJECT_NAME" >> "$LOGFILE" 2>&1 || true
}

# ============================================================
# Phase: notify - 发送通知（模板化）
# ============================================================
notify() {
  local status="${3:-success}"
  local PROJECT_DIR="$WORKSPACE/projects/$PROJECT_NAME"

  if [ "$status" = "success" ]; then
    log "NOTIFY: Sending success notification"

    # 收集数据
    local HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://openginko.tech/$PROJECT_NAME/" 2>/dev/null || echo "000")
    local TECH_STACK="—"
    local TAGLINE="—"
    if [ -f "$PROJECT_DIR/metadata.json" ]; then
      TECH_STACK=$(python3 -c "import json; d=json.load(open('$PROJECT_DIR/metadata.json')); print(' · '.join(d.get('techStack',[])) or '—')" 2>/dev/null || echo "—")
      TAGLINE=$(python3 -c "import json; d=json.load(open('$PROJECT_DIR/metadata.json')); print(d.get('tagline','—'))" 2>/dev/null || echo "—")
    fi

    # 提取五维评分
    local DEPLOY_SCORE="—" META_SCORE="—" LOG_SCORE="—" DESIGN_SCORE="—" RESEARCH_SCORE="—"
    if [ -f "$LOGFILE" ]; then
      DEPLOY_SCORE=$(grep "部署稳定性" "$LOGFILE" | tail -1 | grep -oP '\d+\.\d+|\d+/3' | head -1 || echo "—")
      LOG_SCORE=$(grep "中文本地化" "$LOGFILE" | tail -1 | grep -oP '\d+/3' | head -1 || echo "—")
      DESIGN_SCORE=$(grep "设计一致性" "$LOGFILE" | tail -1 | grep -oP '\d+/3' | head -1 || echo "—")
      META_SCORE=$(grep "功能完整度" "$LOGFILE" | tail -1 | grep -oP '\d+/3' | head -1 || echo "—")
    fi

    # 发送模板通知（ASCII box，避免 Unicode pipe 问题）
    {
      echo "========================================"
      echo "[AI Incubator] 新项目孵化完成"
      echo "========================================"
      echo "项目名称: $PROJECT_NAME"
      echo "一句话:   $TAGLINE"
      echo "访问地址: https://openginko.tech/$PROJECT_NAME/"
      echo "技术栈:   $TECH_STACK"
      echo "----------------------------------------"
      echo "质量评分（四维）:"
      echo "  部署稳定性  $DEPLOY_SCORE"
      echo "  功能完整度  $META_SCORE"
      echo "  设计一致性  $DESIGN_SCORE"
      echo "  中文本地化  $LOG_SCORE"
      echo "========================================"
      echo "HTTP 状态: $HTTP_CODE"
      echo "孵化时间: $(date '+%Y-%m-%d %H:%M')"
    } | send_to_wechat

  else
    log "NOTIFY: Sending failure notification"
    {
      echo "[AI Incubator] 孵化任务异常"
      echo "========================================"
      echo "项目: $PROJECT_NAME"
      echo "状态: 失败"
      echo "请检查日志: $LOGFILE"
    } | send_to_wechat
  fi
}

# ============================================================
# 主调度
# ============================================================
case "$PHASE" in
  setup)
    setup
    ;;
  verify-phase1)
    verify-phase1
    ;;
  verify-phase2)
    verify-phase2
    ;;
  verify-phase3)
    verify-phase3
    ;;
  incubate)
    incubate
    ;;
  build)
    build
    ;;
  deploy)
    deploy
    ;;
  score)
    score
    ;;
  notify)
    notify
    ;;
  *)
    echo "Unknown phase: $PHASE"
    echo "Valid phases: setup, verify-phase1, verify-phase2, verify-phase3, build, deploy, score, notify"
    exit 1
    ;;
esac