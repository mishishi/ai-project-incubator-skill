# AI Project Incubator

从 Idea 到上线交付的 AI 项目孵化器。输入市场调研 → 输出可访问的 Web 应用。

## 功能

- **Phase 1** — 市场调研 + 头脑风暴（tavily-search 驱动）
- **Phase 2** — 设计系统生成（ui-ux-pro-max 驱动）
- **Phase 3** — SPEC + 开发计划
- **Phase 4** — 开发 + 构建 + 部署
- **自动化验证** — 每个 Phase 有 runner.sh 门控，不合格不进入下一 Phase
- **一键孵化** — `runner.sh {proj} incubate` 跑完整流程

## 目录结构

```
ai-project-incubator/
├── SKILL.md              # 技能定义（子 agent 执行指引）
├── KB.md                 # 知识库（已知问题/设计经验/开发陷阱）
├── scripts/
│   ├── runner.sh         # 主入口，子 agent 调用这个
│   ├── build.sh          # 构建 + 重试逻辑
│   ├── deploy.sh         # 部署 + HTTP 验证 + Puppeteer 冒烟测试
│   ├── verify-outputs.sh # 文件验证（字节数门控）
│   ├── preflight.sh      # Phase 0：暂停开关/锁文件/能力边界预扫描
│   ├── collect-showcase.sh # 扫描 incubated/ 生成 Showcase 项目列表
│   ├── generate-card-svg.sh # 生成 Showcase SVG 展示卡片
│   ├── auto-score.sh     # 部署后质量评分
│   ├── update-kb.sh      # 孵化完成更新知识库
│   ├── parse-access-log.sh # 解析 nginx access.log
│   ├── gen-stats.sh      # 生成 Showcase 统计 JSON
│   ├── verify-page.js    # Puppeteer 冒烟测试脚本
│   └── package.json      # Puppeteer 依赖
└── skeleton/             # 项目骨架（Vue3 + TypeScript + i18n）
    ├── package.json      # 固定 vite@^7.0.0 + @vitejs/plugin-react@^4.7.0
    ├── vite.config.ts
    ├── metadata.json
    └── src/
        ├── App.tsx
        ├── LanguageContext.tsx
        ├── main.tsx
        └── i18n/
            ├── en.ts
            └── zh.ts
```

---

## 快速开始

### 1. 克隆到 workspace

```bash
cd /root/.openclaw/workspace/skills
git clone git@github.com:mishishi/ai-project-incubator-skill.git ai-project-incubator
chmod +x ai-project-incubator/scripts/*.sh
```

### 2. 安装依赖 Skill

```bash
# 市场调研需要
openclaw skills add openclaw-tavily-search

# 设计系统生成需要
openclaw skills add ui-ux-pro-max
```

### 3. 配置环境变量

```bash
# Tavily 搜索 API（在 https://tavily.com 获取）
export TAVILY_API_KEY="tvly-xxxx"
```

### 4. 安装脚本依赖（可选）

仅当需要 Puppeteer 冒烟测试时安装：

```bash
cd /root/.openclaw/workspace/skills/ai-project-incubator/scripts
npm install
```

### 5. 验证安装

```bash
bash /root/.openclaw/workspace/skills/ai-project-incubator/scripts/runner.sh test-project setup
# 输出：SETUP: Project created 表示成功
```

---

## 使用方式

### 方式一：分步执行（推荐，Phase 之间可人工检查）

```bash
# 创建项目骨架
bash scripts/runner.sh my-project setup

# Phase 1：市场调研
# ...子 agent 编辑 research.md...
bash scripts/runner.sh my-project verify-phase1

# Phase 2：设计系统
# ...子 agent 调用 design_system.py，写 design-system.md...
bash scripts/runner.sh my-project verify-phase2

# Phase 3：SPEC + Plan
# ...子 agent 写 SPEC.md 和 PLAN.md...
bash scripts/runner.sh my-project verify-phase3

# Phase 4：构建 + 部署
bash scripts/runner.sh my-project build
bash scripts/runner.sh my-project deploy
```

### 方式二：一键孵化（适合自动化 cron）

```bash
bash scripts/runner.sh my-project incubate
```

会依次执行：setup → verify-phase1 → verify-phase2 → verify-phase3 → build → deploy
**build 失败则 abort，不会继续 deploy。**

### 方式三：单独执行单个命令

```bash
bash scripts/runner.sh my-project build      # 只构建
bash scripts/runner.sh my-project deploy     # 只部署
bash scripts/runner.sh my-project score      # 质量评分
```

---

## runner.sh 命令参考

| 命令 | 验证内容 | 失败行为 |
|------|---------|---------|
| `setup` | skeleton 复制到 workspace/projects/ | 退出码 1 |
| `verify-phase1` | research.md ≥ 100字节 | 退出码 1 |
| `verify-phase2` | design-system.md ≥ 200字节 | 退出码 1 |
| `verify-phase3` | SPEC.md + PLAN.md ≥ 100字节 | 退出码 1 |
| `build` | npm run build 成功 | 退出码 1，abort 后续流程 |
| `deploy` | HTTP 200 + dist/ 存在 | 退出码 1 |
| `incubate` | 依次执行 setup → verify-phase1~3 → build → deploy | 任意失败 abort |

---

## Phase 输出规范

### Phase 1 — research.md

必须包含以下五个节：

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
- 每条趋势必须注明来源
- 每个竞品必须包含定价信息
- 输出必须包含中文文字

### Phase 2 — design-system.md

必须包含：

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

### Phase 3 — SPEC.md

```markdown
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

### 1.2 <功能名称>
...

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

### Phase 3 — PLAN.md

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

---

## Phase 4 完成后必须创建

### metadata.json（Showcase 必须）

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

### 部署路径

部署后应用访问地址：`https://openginko.tech/{project-name}/`

Nginx 实际路径：`/usr/share/nginx/html/{project-name}/`

---

## 暂停开关

```bash
# 暂停（跳过本次孵化）
touch /root/.openclaw/incubator.paused

# 恢复
rm /root/.openclaw/incubator.paused

# 查看状态
[ -f /root/.openclaw/incubator.paused ] && echo "PAUSED" || echo "ACTIVE"
```

暂停后 cron 触发时会跳过本次孵化（退出码 0，不通知）。

---

## 日志

所有日志写入：`/root/.openclaw/logs/incubator.log`

包含：Phase 开始/完成时间、build/deploy 失败及重试、自动化评分结果。

---

## 知识库

`KB.md` 记录孵化过程中发现的已知问题、设计经验、开发陷阱。每次孵化完成 `update-kb.sh` 自动追加当天日期条目。

子 agent 应主动将新问题追加到对应分类。

---

## 注意事项

1. **禁止使用 playwright-mcp** — 存在进程泄漏，会在凌晨自动化环境中持续累积残留进程
2. **禁止直接修改 `/etc/`、`/usr/lib/`、`/var/lib/` 等系统目录**
3. **禁止申请新域名或子域名**
4. **禁止调用付费 API 超过 ¥10/次**
5. **部署路径只能使用 `/usr/share/nginx/html/`**
6. **所有界面文字必须中文化**（禁止上线纯英文产品）
7. **图标禁止使用 emoji**，统一使用 Lucide SVG 或内联 SVG

---

## 定制化

### 修改部署域名

编辑 `scripts/deploy.sh`，把 `https://openginko.tech` 替换为你的域名：

```bash
DOMAIN="https://your-domain.com"
```

### 修改 skeleton 项目模板

直接编辑 `skeleton/` 目录下的文件，下次 `runner.sh setup` 会使用更新后的模板。

### 修改设计风格

当前默认风格是 Literary Dark（#0F0F0E 背景 + #E07A3A 强调色）。

如需更换，在 `SKILL.md` 的"设计系统要求"部分修改对应 token 值。

---

## 故障排除

### build 失败：ERESOLVE unable to resolve dependency tree

检查 `skeleton/package.json` 中 `vite` 版本。当前应使用 `^7.0.0`（不要用 ^8.0.0，因为 `@vitejs/plugin-react` 暂不支持 Vite 8）。

### build 失败：tsc: not found

使用 `npx tsc` 或修改 `skeleton/package.json` 的 build script：

```json
"build": "npx tsc -b && vite build"
```

### deploy 后 HTTP 200 但页面空白

检查 `dist/index.html` 是否包含 `src="/assets/`（相对路径问题）。在 `vite.config.ts` 确保：

```ts
base: '/{project-name}/'
```

而非 `base: '/'`。

### Puppeteer 冒烟测试失败

`verify-page.js` 会检查页面控制台是否无 JS Error。如测试失败，可暂时跳过：在 `deploy.sh` 中注释掉调用 `verify-page.js` 的行。

---

## 与 Showcase 集成

孵化完成后会自动：

1. 将项目移动到 `workspace/projects/incubated/`
2. 生成双尺寸 SVG 卡片（card 361×170 / modal 511×220）
3. 更新 `showcase/projects.json`

Showcase 展示页面需另外部署，参考：[ai-incubator-showcase](git@github.com:mishishi/ai-incubator-showcase.git)