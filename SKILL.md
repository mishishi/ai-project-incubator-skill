---
name: ai-project-incubator
description: "AI 项目孵化器：每天凌晨自动头脑风暴一个 Idea，完成设计文档、SPEC、Plan，最终交付一个响应式 Web 应用。前端必须使用 ui-ux-pro-max 设计 UX，技术栈为 React + TypeScript + Vite + Tailwind v4，后端用 Fastify（如需要）。"
metadata:
  version: "2.2.0"
  lastUpdated: "2026-05-18"
  changelog:
    - "2.2.0: Showcase SVG 双尺寸支持（首页 361×170 / 弹窗 511×220），Terminal + Neon 风格，generate-card-svg.sh 支持 card/modal 双模式"
    - "1.3.0: 新增能力边界强制执行、知识回流强制机制、最小交付底线技术验证、质量评分自动化、暂停开关"
    - "1.2.0: 新增放弃规则、最小交付底线、能力边界、强制知识回流、skeleton可运行示例、日志自动分析"
    - "1.1.0: 新增Phase0预检、状态锁文件、质量评分、依赖声明、版本标识、cron消息规范、项目保留策略"
    - "1.0.0: 初始版本"
  dependsOn:
    - skill: ui-ux-pro-max
      reason: "design_system.py 生成设计 token"
    - skill: openclaw-tavily-search
      reason: "市场调研 API 调用"
  capabilities:
    canCall:
      - "openclaw-tavily-search"
      - "ui-ux-pro-max"
    canDeployTo:
      - "/usr/share/nginx/html/{project-name}/"
    cannot:
      - "修改 Nginx 配置"
      - "申请新域名或子域名"
      - "调用付费 API 超过 ¥10/次"
      - "修改系统文件（/etc/, /usr/lib/, /var/lib/ 等）"
      - "部署到 /usr/share/nginx/html/ 以外的路径"
    mustConfirm:
      - "调用任何需要付费的服务"
      - "需要用户账号或认证信息的操作"
---

# AI 项目孵化器

每天凌晨 00:00 自动运行，从市场调研到产品交付，完整跑通一个 AI 项目的孵化流程。

**子 agent 执行模式**：Phase 工作 + runner.sh 验证交替执行

```bash
# 子 agent 每步完成后调用 runner.sh 验证
bash /root/.openclaw/workspace/skills/ai-project-incubator/scripts/runner.sh {project-name} setup
# 子 agent 做 Phase 1 工作（调研 + 头脑风暴）...
bash /root/.openclaw/workspace/skills/ai-project-incubator/scripts/runner.sh {project-name} verify-phase1
# 子 agent 做 Phase 2 工作（设计系统）...
bash /root/.openclaw/workspace/skills/ai-project-incubator/scripts/runner.sh {project-name} verify-phase2
# 子 agent 做 Phase 3 工作（SPEC + Plan）...
bash /root/.openclaw/workspace/skills/ai-project-incubator/scripts/runner.sh {project-name} verify-phase3
# 子 agent 做 Phase 4 工作（开发）...
bash /root/.openclaw/workspace/skills/ai-project-incubator/scripts/runner.sh {project-name} build
bash /root/.openclaw/workspace/skills/ai-project-incubator/scripts/runner.sh {project-name} deploy
bash /root/.openclaw/workspace/skills/ai-project-incubator/scripts/runner.sh {project-name} score
bash /root/.openclaw/workspace/skills/ai-project-incubator/scripts/runner.sh {project-name} notify success
```

**runner.sh 验证命令说明**：
| 命令 | 验证内容 | 失败行为 |
|------|---------|---------|
| `runner.sh X setup` | skeleton 复制成功 | 退出码 1 |
| `runner.sh X verify-phase1` | research.md ≥ 100字节 | 退出码 1 |
| `runner.sh X verify-phase2` | design-system.md ≥ 200字节 | 退出码 1 |
| `runner.sh X verify-phase3` | SPEC.md + PLAN.md ≥ 100字节 | 退出码 1 |
| `runner.sh X build` | npm run build 成功 + 超时检查 | 退出码 1 |
| `runner.sh X deploy` | HTTP 200 + 路径检查 | 退出码 1 |

**子 agent 只需要调用这些命令**，不需要自己写验证脚本。

---

## 脚本目录

```
/root/.openclaw/workspace/skills/ai-project-incubator/scripts/
├── runner.sh          # 主入口（全流程自动化，子 agent 执行这个）
├── preflight.sh      # Phase 0：预检 + 暂停开关 + 锁文件 + 能力边界预扫描
├── verify-outputs.sh # Phase 1-3 输出验证（文件存在 + 最小字节数）
├── build.sh          # Phase 4：构建 + 超时检查 + 失败重试
├── deploy.sh         # Phase 4：部署 + HTTP 验证
├── auto-score.sh      # 后置：自动化质量评分
└── update-kb.sh      # 后置：KB.md 强制更新
```

---

## 孵化流程

### Phase 0：预检（自动执行）

---

## 环境变量（子 agent 执行前必须配置）

| 变量 | 值 | 说明 |
|------|-----|------|
| `TAVILY_API_KEY` | `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` | Tavily 搜索 API |

---

`preflight.sh` 自动完成以下检查，任意一步失败则终止：

| 检查项 | 失败行为 |
|--------|---------|
| 暂停开关 `/root/.openclaw/incubator.paused` 存在 | 跳过本次孵化（退出码 0，不通知）|
| 锁文件 `/root/.openclaw/incubator.lock` 存在且上一个任务仍在跑 | 跳过本次孵化（退出码 0，不通知）|
| Nginx 配置有效 | 记录错误，终止 |
| 部署目录可写 | 记录错误，终止 |
| SKILL.md 和 skeleton 存在 | 记录错误，终止 |
| 能力边界预扫描（付费 API / 系统文件修改 / Nginx 修改）| 违规直接终止并通知 |

---

### Phase 1：市场调研 + 头脑风暴（时间盒：25 分钟）

**子 agent 负责执行，采用多轮迭代逐步深入**:

**第 1 轮 — 趋势扫描（5 分钟）**
1. 调用 `openclaw-tavily-search` 搜索最近 7 天 AI 工具发布/论文/开源项目
2. 从搜索结果中提取 3 条具体趋势，每条注明来源（如 "来源：ProductHunt 2026" 或类似）
3. 头脑风暴 3 个可行方向

**第 2 轮 — 竞品深挖（8 分钟）**
1. 选定最有价值的 1 个方向
2. 调用 `openclaw-tavily-search` 搜索这个方向下的 3 个竞品
3. 每个竞品记录：定价 / 目标用户 / 核心弱点（每项一句话）
4. 评估市场规模和进入壁垒

**第 3 轮 — 方向筛选（7 分钟）**
1. 综合趋势 + 竞品分析，评估选定方向的潜力
2. 明确目标用户人群划分
3. 判断是否值得孵化，如不值得则回第 1 轮重新选方向（最多重试 1 次）

**第 4 轮 — 输出整理（5 分钟）**
1. 按格式输出 `research.md`

**`research.md` 输出格式规范**（子 agent 必须遵循，以便孵化日志解析器提取结构化数据）：

```markdown
## 市场数据
> 市场规模数据（$xxx CAGR xx%），来源：<搜索来源>

## 趋势分析
- **趋势1**: <一句话描述>（来源：<来源>）
- **趋势2**: <一句话描述>（来源：<来源>）
- **趋势3**: <一句话描述>（来源：<来源>）

## 竞品分析
- **竞品名称**: 定价/<目标用户>/<核心弱点>

## 目标用户
> <人群划分，一句话>

## 技术栈建议
> <逗号分隔的技术栈>
```

**格式要求**：
- 必须使用 `## 市场数据`、`## 趋势分析`、`## 竞品分析`、`## 目标用户`、`## 技术栈建议` 作为各节标题
- 每条趋势必须注明来源（如 "来源：ProductHunt 2026"）
- 每个竞品必须包含定价信息
- 输出必须包含中文文字

**完成后**：`verify-outputs.sh` 验证 `research.md` 包含：
- 市场规模数据（含 $ 或 %）
- 至少 3 个竞品（含定价）
- 至少 3 条趋势（含来源）
- 目标用户描述

如验证不通过，迭代优化 `research.md` 直到通过（最多 2 轮自检）

**⚠️ 放弃条件**（满足任一则停止）：
- 找不到任何可行方向
- 竞品分析后市场规模明显不足（无可衡量数据）
- 方向需要 skill 范围外的技术栈
- 方向需要付费 API 且无法确认费用
- 重试 1 次后仍无满意方向

---

### Phase 2：设计文档

**子 agent 负责执行**：
1. 调用 `ui-ux-pro-max/scripts/design_system.py`，传入 Idea + Literary Dark 关键词
2. 生成设计系统 token（颜色/字体/间距/动画）
3. 按自检清单逐项检查（6 项），最多 3 轮
4. 输出 `design-system.md`

**`design-system.md` 输出格式规范**（子 agent 必须遵循）：

```markdown
## 设计方向
**风格**: <风格名称>

## 色彩系统
| Token | 色值 | 用途 |
|-------|------|------|
| `--color-bg` | `#0F0F0E` | 主背景 |

## 字体系统
**标题字体**: <字体名 + fallback>
**正文字体**: <字体名 + fallback>
**代码字体**: <字体名 + fallback>
```

**格式要求**：
- 必须有 `## 设计方向` 含风格名称
- 必须有 `## 色彩系统` 含颜色表格（Token 列用 `--color-name` 格式）
- 必须有 `## 字体系统` 含标题/正文/代码字体
- 颜色 Token 用 `--color-name` 格式（如 `--color-accent`）
- 输出必须包含中文文字

**完成后**：`verify-outputs.sh` 验证 `design-system.md` ≥ 200 字节

**⚠️ 放弃条件**：自检 3 轮后仍有 token 不符合规范

---

### Phase 3：SPEC + Plan

**子 agent 负责执行**：
1. 写 SPEC.md（产品描述/用户/功能列表/数据模型/API）
2. 写 PLAN.md（开发步骤 ≤ 5 步/排期/里程碑）
3. 按后端决策规则判断是否需要后端
4. 输出 `SPEC.md` + `PLAN.md`

**`SPEC.md` 输出格式规范**（子 agent 必须遵循）：

```markdown
## 产品概述
**产品名**: <产品名>
**一句话描述**: <AI 辅助的 xxx，用于 xxx>
**目标用户**: <目标用户描述>

## 核心功能
### 1.1 <功能名称>
<一句话功能描述>
### 1.2 <功能名称>
<一句话功能描述>
### 1.3 <功能名称>
<一句话功能描述>
```

**`PLAN.md` 输出格式规范**（子 agent 必须遵循）：

```markdown
## 开发步骤
### Step 1: <阶段名称>
- [x] <已完成步骤1>
- [ ] <待完成步骤2>

### Step 2: <阶段名称>
- [ ] <待完成步骤>

## 里程碑
| 里程碑 | 完成标准 |
|--------|----------|
| M1：<名称> | <完成标准> |
| M2：<名称> | <完成标准> |
```

**格式要求**：
- SPEC.md 必须有 `## 产品概述` 包含产品名/一句话描述/目标用户
- SPEC.md 功能用 `### 1.1`, `### 1.2`, `### 1.3` 格式
- PLAN.md 用 `### Step 1:`, `### Step 2:` 格式标记阶段
- PLAN.md 完成项用 `- [x]`，待完成项用 `- [ ]`
- PLAN.md 里程碑用表格格式（含 M1/M2 等标记）
- 所有输出必须包含中文文字

**完成后**：`verify-outputs.sh` 验证两者 ≥ 100 字节

**简化决策**（Phase 4 超时 45 分钟时启用）：
- 减少非核心功能
- 移除后端改用 localStorage
- 跳过 Onboarding
- 专注核心功能 + build 成功

---

### Phase 4：实现开发

**子 agent 负责执行**：
1. 开发核心功能（使用 design-system.md token）
2. 调用 `bash runner.sh {project-name} incubate` — 一键完成 verify → build → deploy

**⚠️ 禁止使用 playwright-mcp**（存在进程泄漏，会在凌晨自动化环境中持续累积残留进程）

**完成后**：curl 验证 `https://openginko.tech/{project-name}/` 返回 HTTP 200

---

## 暂停开关

**人工干预**：无需修改 cron，直接文件系统控制。

```bash
# 暂停（跳过本次孵化）
touch /root/.openclaw/incubator.paused

# 恢复
rm /root/.openclaw/incubator.paused

# 查看状态
[ -f /root/.openclaw/incubator.paused ] && echo "⏸ PAUSED" || echo "▶ ACTIVE"
```

---

## 设计系统要求（Literary Dark）

| token | 值 | 用途 |
|-------|---|------|
| 背景 | #0F0F0E | 页面底色 |
| 主文字 | #E8E4DC | 标题/正文 |
| 强调色 | #E07A3A | 按钮/链接/高亮 |
| 次要文字 | #8A857A | 说明/辅助 |
| 边框 | #33302A | 分隔线/输入框 |
| 悬停 | #44403A | 按钮悬停 |
| Surface | #1A1917 / #252420 | 卡片/面板 |

**字体**：标题 Lora（衬线）/ 界面 Inter / 等宽 Fira Code

**按钮**：`rounded-xl` + `transition-colors duration-150`，其他规范见设计系统文件

**去 Emoji**：所有图标用 Lucide SVG 或内联 SVG

---

## 语言与本地化要求

**默认语言为中文**：禁止上线纯英文产品，所有界面文字必须中文化

**i18n 规范**：
- React Context 方案，不依赖外部库
- localStorage key：`{project-name}_lang`，默认 zh
- 语言文件：`src/i18n/en.ts` / `src/i18n/zh.ts`
- 切换组件：页面左上角，Globe 图标

---

## 新人引导（Onboarding）

**适用场景**：复杂交互项目（如图谱编辑器、多步骤流程）

**简化规则**：Phase 4 超时时可跳过

**规范**：
- `OnboardingGuide.tsx` 组件，首次访问自动显示
- 半透明黑色 overlay + 白色卡片，分步骤介绍
- `data-onboard` 属性标记目标元素
- localStorage key：`{project-name}_onboarded`

---

## 监控与日志

日志文件：`/root/.openclaw/logs/incubator.log`

记录内容：
- Phase 开始/完成时间
- 暂停开关 / 锁文件跳过事件
- 能力边界警告
- build/deploy 失败及重试
- 自动化评分结果

---

## 知识回流（强制）

**KB.md 位置**：`/root/.openclaw/workspace/skills/ai-project-incubator/KB.md`

每次孵化完成（成功或失败），`update-kb.sh` 自动追加当天日期条目。子 agent 应主动将新发现的问题追加到 KB.md 对应分类（已知问题 / 设计经验 / 开发陷阱）。

---

## 项目输出位置

```
/root/.openclaw/workspace/projects/{project-name}/
├── research.md        # 市场调研 + Idea
├── design-system.md   # 设计系统 token
├── SPEC.md            # 功能规格
├── PLAN.md            # 开发计划
├── src/               # React 前端
│   ├── i18n/          # 国际化
│   ├── OnboardingGuide.tsx  # 新手指引（如有）
│   └── ...
├── server/            # Fastify 后端（如有）
└── dist/              # 构建产物
```

Nginx 部署路径：`/usr/share/nginx/html/{project-name}/`

### metadata.json（Showcase 必须）

每个孵化的项目必须在根目录包含 `metadata.json`，供 Showcase 展示页面自动采集：

```json
{
  "name": "项目目录名（小写+连字符）",
  "tagline": "一句话描述（≤20字）",
  "description": "详细描述（1-2句）",
  "techStack": ["React", "TypeScript", "Tailwind", "Vite"],
  "features": ["功能1", "功能2", "功能3"],
  "incubatedAt": "YYYY-MM-DD",
  "screenshot": "screenshot.png"

子 agent 在 Phase 4 开发完成后负责创建此文件。

### Showcase SVG 卡片

部署完成后，runner.sh 自动调用 `generate-card-svg.sh` 生成 Terminal + Neon 风格的 SVG 展示卡片（无需子 agent 干预）：

```bash
# 生成首页卡片 SVG（默认 361×170）
bash /root/.openclaw/workspace/skills/ai-project-incubator/scripts/generate-card-svg.sh {project-name} card

# 生成弹窗大图 SVG（511×220）
bash /root/.openclaw/workspace/skills/ai-project-incubator/scripts/generate-card-svg.sh {project-name} modal
```

### Showcase 采集

部署完成后，运行采集脚本更新 Showcase 数据：

```bash
bash /root/.openclaw/workspace/skills/ai-project-incubator/scripts/collect-showcase.sh
```

---

## 交付通知

**发送前验证**：
1. curl `https://openginko.tech/{project-name}/` 返回 HTTP 200
2. `dist/index.html` 不含 `src="/assets/` 路径
3. `KB.md` 已更新

**成功通知**（微信纯文本，禁止 markdown）：
```
新项目上线：{项目名}
{一句话描述}
访问地址：https://openginko.tech/{project-name}/
技术栈：React + TypeScript + Vite + Tailwind{+ Fastify（如有）}
主要功能：{3 条核心功能}
```

**失败通知**：
```
孵化任务异常：{项目名}
原因：{失败阶段}——{错误描述}
请检查日志：/root/.openclaw/logs/incubator.log
```

---

## Cron 触发消息规范

**Job 消息必须包含 Skill 路径引用**：

```
请执行 ai-project-incubator skill（读取 /root/.openclaw/workspace/skills/ai-project-incubator/SKILL.md v2.0.0），通过 bash runner.sh 完成从市场调研到产品交付的完整孵化流程。技术栈：React+TS+Vite+Tailwind+Fastify，设计风格：Literary Dark。
```

**重要**：禁止在 cron 消息里重写 SKILL.md 内容，执行指令必须引用 runner.sh。

---

## 工作流程模板

```
## Day-N 孵化日志

### Idea
{Idea + 一句话描述}

### 设计系统
{token 数量 + 核心颜色 + 主要字体}

### SPEC 摘要
{核心功能列表（最多 5 条）}

### 技术选型
{为什么需要/不需要后端}

### 开发状态
- [x] Phase 0 预检 + 能力边界
- [x] Phase 1 市场调研
- [x] Phase 2 设计系统
- [x] Phase 3 SPEC + Plan
- [x] Phase 4 开发 + 部署

### 问题与解决
{遇到的问题及解决方案}

### 简化决策（如有）
{跳过某功能的原因}

### 知识沉淀
{建议追加到 KB.md 的内容}

### 交付评分（自动化）
{auto-score.sh 输出}

### 交付地址

项目名已知，直接构造生产 URL：

```bash
PROD_URL="https://openginko.tech/$PROJECT_NAME/"
```

**禁止使用 `http://localhost/` 或 `http://127.0.0.1/`**，所有报告必须使用生产域名。