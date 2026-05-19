---
name: ai-project-incubator
description: "AI 项目孵化器：从 Idea 到上线交付，完整跑通市场调研→设计系统→SPEC→开发→部署的 Web 应用孵化流程。前端 React+TS+Vite+Tailwind，部署到 https://openginko.tech/{project-name}/"
metadata:
  version: "3.0.0"
  lastUpdated: "2026-05-19"
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

## 命令参考

```bash
# 子 agent 调用 runner.sh 驱动完整流程（路径相对于 skill 根目录）
bash scripts/runner.sh {project-name} setup
bash scripts/runner.sh {project-name} verify-phase1
bash scripts/runner.sh {project-name} verify-phase2
bash scripts/runner.sh {project-name} verify-phase3
bash scripts/runner.sh {project-name} build
bash scripts/runner.sh {project-name} deploy

# 一键孵化（完整流程，build 失败则 abort）
bash scripts/runner.sh {project-name} incubate
```

| 命令 | 验证内容 | 失败行为 |
|------|---------|---------|
| `setup` | skeleton 复制成功 | 退出码 1 |
| `verify-phase1` | research.md ≥ 100字节 | 退出码 1 |
| `verify-phase2` | design-system.md ≥ 200字节 | 退出码 1 |
| `verify-phase3` | SPEC.md + PLAN.md ≥ 100字节 | 退出码 1 |
| `build` | npm run build 成功 | 退出码 1，abort 后续流程 |
| `deploy` | HTTP 200 + dist/ 存在 | 退出码 1 |
| `incubate` | 依次执行 setup → verify-phase1~3 → build → deploy | 任意失败 abort |

---

## 脚本目录

```
/root/.openclaw/workspace/skills/ai-project-incubator/scripts/
├── runner.sh              # 主入口（子 agent 调用这个）
├── build.sh               # npm build + 重试逻辑（runner.sh build 调用）
├── deploy.sh              # 部署 + HTTP 验证 + 移动到 incubated/（runner.sh deploy 调用）
├── verify-outputs.sh       # 文件存在性验证（子 agent 可选调用）
├── preflight.sh            # Phase 0：暂停开关/锁文件/能力边界预扫描
├── collect-showcase.sh     # 扫描 incubated/ 生成 showcase/projects.json
├── generate-card-svg.sh    # 生成 Showcase SVG 展示卡片
├── auto-score.sh           # 部署后质量评分
├── update-kb.sh            # 孵化完成后更新 KB.md
├── parse-access-log.sh     # 解析 nginx access.log
├── gen-stats.sh            # 生成 Showcase 统计 JSON
├── verify-page.js          # puppeteer 冒烟测试脚本（deploy.sh 调用）
└── package.json            # puppeteer 依赖（npm install 后使用）
```

---

## 工作流程

### Phase 1：市场调研 + 头脑风暴（时间盒：25 分钟）

**子 agent 负责执行，采用多轮迭代逐步深入**:

**第 1 轮 — 趋势扫描（5 分钟）**
1. 调用 `openclaw-tavily-search` 搜索最近 7 天 AI 工具发布/论文/开源项目
2. 从搜索结果中提取 3 条具体趋势，每条注明来源（如 "来源：ProductHunt 2026"）
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

**`research.md` 输出格式规范**（子 agent 必须遵循）——优先使用结构化格式，解析器优先匹配结构化，fallback 才会走节标题解析：

```markdown
## 关键决策
市场: <市场规模数据>（$xxx CAGR xx%），来源：<搜索来源>
趋势1: <一句话描述>（来源：<来源>）
趋势2: <一句话描述>（来源：<来源>）
趋势3: <一句话描述>（来源：<来源>）
竞品: <竞品名称>（定价/目标用户/核心弱点，一句话）
目标用户: <人群划分，一句话>
技术栈: <逗号分隔的技术栈>

## 市场数据
> <详细市场规模数据，可含链接>

## 趋势分析
- **趋势1**: <一句话描述>（来源：<来源>）
- **趋势2**: <一句话描述>（来源：<来源>）

## 竞品分析
- **竞品名称**: 定价/<目标用户>/<核心弱点>

## 目标用户
> <人群划分详细描述>

## 技术栈建议
> <逗号分隔的技术栈>
```

**格式要求**：
- 必须包含 `## 关键决策` 一节，每行以 `key: value` 格式开头（解析器优先读取这个格式）
- 可选包含详细节内容（`## 市场数据` 等）供人工查阅，但关键决策必须简洁
- `竞品:` 行可以重复多行，每个竞品一行
- 输出必须包含中文文字

完成后：子 agent 可选调用 `verify-outputs.sh` 自检，或直接用 `runner.sh verify-phase1` 验证。

**放弃条件**（满足任一则停止）：
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

**`design-system.md` 输出格式规范**——优先使用结构化格式，解析器优先匹配结构化：

```markdown
## 关键决策
风格: <风格名称>
字体: 标题 <字体名 + fallback>
字体: 正文 <字体名 + fallback>
色彩: <色值> (<用途>)

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
- 必须包含 `## 关键决策` 一节，每行以 `key: value` 格式开头（解析器优先读取这个格式）
- `字体:` 行可重复（标题/正文/代码各一行）

**格式要求**：
- 必须有 `## 设计方向` 含风格名称
- 必须有 `## 色彩系统` 含颜色表格（Token 列用 `--color-name` 格式）
- 必须有 `## 字体系统` 含标题/正文/代码字体
- 颜色 Token 用 `--color-name` 格式（如 `--color-accent`）
- 输出必须包含中文文字

完成后：用 `runner.sh verify-phase2` 验证 ≥ 200 字节。

**放弃条件**：自检 3 轮后仍有 token 不符合规范

---

### Phase 3：SPEC + Plan

**子 agent 负责执行**：
1. 写 SPEC.md（产品描述/用户/功能列表/数据模型/API）
2. 写 PLAN.md（开发步骤 ≤ 5 步/排期/里程碑）
3. 按后端决策规则判断是否需要后端
4. 输出 `SPEC.md` + `PLAN.md`

**`SPEC.md` 输出格式规范**——优先使用结构化格式，解析器优先匹配结构化：

```markdown
## 关键决策
定位: <一句话产品定位>
用户: <人群划分，一句话>
核心价值: <一句话核心价值主张>
解决问题: <目标用户面临什么具体问题>
技术: <是否需要后端 + localStorage 结构 + 状态管理方案，一句话>

## 产品概述
**产品名**: <产品名>
**一句话描述**: <AI 辅助的 xxx，用于 xxx>
**解决问题**: <目标用户面临什么具体问题>

## 用户画像
- **用户A**: <人群描述>——<核心诉求>

## 核心功能
### 1.1 <功能名称>
- 描述：<一句话功能描述>
- 用户流程：<用户从进入页面到完成操作的完整路径>
- 输入：<用户提供了什么数据/信息>
- 输出：<用户得到了什么结果>
- 边界：<空数据/加载中/网络失败时显示什么>

## 数据模型
- `Entity`: 字段1 / 字段2 / 字段3
- `Entity`: ...

## 技术决策
- 为什么不需要后端（或为什么需要）
- localStorage 结构设计
- 状态管理方案（Zustand / Context / useState）

## 边界情况
- 网络离线：<显示什么提示>
- 空数据：<首次使用时显示什么>
- 数据损坏：<如何恢复>
```

**格式要求**：
- 必须包含 `## 关键决策` 一节，每行以 `key: value` 格式开头（解析器优先读取这个格式）
- `技术:` 行一句话概括技术决策（后端必要性、存储方案、状态管理）
- `用户:` 行可重复多行，每个用户群体一行

**`PLAN.md` 输出格式规范**：

```markdown
## 开发步骤
### Step 1: <阶段名称>（预计 N 分钟）
- [ ] <步骤描述>
- 完成标准：<什么情况下算这个 Step 完成>

### Step 2: <阶段名称>（预计 N 分钟）
- [ ] <步骤描述>
- 完成标准：<什么情况下算这个 Step 完成>

## 里程碑
| 里程碑 | 完成标准 |
|--------|----------|
| M1：<名称> | <功能+体验标准> |
| M2：<名称> | <功能+体验标准> |
```

**格式要求**：
- PLAN.md 必须有 `## 开发步骤` 和 `## 里程碑`
- 每个 Step 必须标注预计时间（分钟），便于子 agent 根据剩余时间决策跳过顺序
- 每个 Step 必须有完成标准（什么是"做完"），避免开发时无限扣细节
- Step 完成项用 `- [x]`，待完成项用 `- [ ]`
- 里程碑用表格格式（含 M1/M2 等标记），每条完成标准需包含功能+体验两点
- 所有输出必须包含中文文字

完成后：用 `runner.sh verify-phase3` 验证两者 ≥ 100 字节。

**简化决策**（Phase 4 超时 45 分钟时启用）：
- 减少非核心功能
- 移除后端改用 localStorage
- 跳过 Onboarding
- 专注核心功能 + build 成功

---

### Phase 4：实现开发

**子 agent 负责执行**：
1. 开发核心功能（使用 design-system.md token）
2. 调用 `bash runner.sh {project-name} build` — **只调用一次，不重复调用**
3. 调用 `bash runner.sh {project-name} deploy` — **只调用一次，不重复调用**
4. **禁止自行执行 `npm run build`、`mkdir`、`mv`、`cp` 等文件操作**，全部由 runner.sh 完成

**build 失败则 abort，不会继续 deploy。**

**⚠️ 禁止使用 playwright-mcp**（存在进程泄漏）

完成后：curl 验证 `https://openginko.tech/{project-name}/` 返回 HTTP 200

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

**按钮**：`rounded-xl` + `transition-colors duration-150`

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

## 暂停开关

**人工干预**：无需修改 cron，直接文件系统控制。

```bash
# 暂停（跳过本次孵化）
touch /root/.openclaw/incubator.paused

# 恢复
rm /root/.openclaw/incubator.paused

# 查看状态
[ -f /root/.openclaw/incubator.paused ] && echo "PAUSED" || echo "ACTIVE"
```

---

## 项目输出位置

```
/root/.openclaw/workspace/projects/{project-name}/
├── research.md        # 市场调研 + Idea
├── design-system.md   # 设计系统 token
├── SPEC.md            # 功能规格
├── PLAN.md            # 开发计划
├── metadata.json      # Showcase 必须文件
├── src/               # React 前端
│   ├── i18n/          # 国际化
│   ├── OnboardingGuide.tsx  # 新手指引（如有）
│   └── ...
└── dist/              # 构建产物
```

Nginx 部署路径：`/usr/share/nginx/html/{project-name}/`

### metadata.json（Showcase 必须）

每个孵化的项目必须在根目录包含 `metadata.json`：

```json
{
  "name": "项目目录名（小写+连字符）",
  "tagline": "一句话描述（≤20字）",
  "description": "详细描述（1-2句）",
  "techStack": ["React", "TypeScript", "Tailwind", "Vite"],
  "features": ["功能1", "功能2", "功能3"],
  "incubatedAt": "YYYY-MM-DD",
  "screenshot": "screenshot.png"
}
```

子 agent 在 Phase 4 开发完成后负责创建此文件。

---

## Showcase 数据更新

**SVG 展示卡片**：deploy 时自动生成（card 361×170 / modal 511×220），无需子 agent 干预。

**Showcase 项目列表**：deploy 后自动调用 `collect-showcase.sh` 更新 `showcase/projects.json`。

---

## 知识回流

**KB.md 位置**：`/root/.openclaw/workspace/skills/ai-project-incubator/KB.md`

每次孵化完成（成功或失败），`update-kb.sh` 自动追加当天日期条目。子 agent 应主动将新发现的问题追加到 KB.md 对应分类（已知问题 / 设计经验 / 开发陷阱）。

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

## 日志

日志文件：`/root/.openclaw/logs/incubator.log`

记录内容：
- Phase 开始/完成时间
- 暂停开关 / 锁文件跳过事件
- 能力边界警告
- build/deploy 失败及重试
- 自动化评分结果

**禁止使用 `http://localhost/`**，所有报告必须使用生产域名 `https://openginko.tech/`。