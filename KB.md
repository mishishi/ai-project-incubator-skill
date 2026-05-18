# AI Incubator Knowledge Base

积累每次孵化的经验教训，避免重复踩坑。

---

## 已知问题

- {日期}：发现 {问题}，解决方法是 {方案}
- 2026-05-18：构建后 index.html 漏复制到根目录导致 403 — deploy 命令必须单独执行 `cp dist/index.html /path/index.html`
- 2026-05-18：useNavigate() 在 App 组件顶层调用时 Router 上下文未建立 — 移到子组件内调用
- 2026-05-18：vite.config.ts 的 base 参数必须与部署路径一致，否则 asset 路径 404

---

## 设计经验

- {日期}：发现 {发现}，建议 {做法}
- 2026-05-18：目标用户为国内用户时，默认语言必须为中文，禁止上线纯英文产品
- 2026-05-18：中文模板名称比英文更符合国内用户直觉（三幕结构 > 3-Act Structure）

---

## 开发陷阱

- {日期}：遇到 {错误}，因为 {原因}，修复方式是 {方法}
- 2026-05-18：React Router v7 BrowserRouter 必须在 App 组件外层，不能在调用 useNavigate 的同一组件内
- 2026-05-18：复制 skeleton 后 {project-name} 占位符必须全部替换，否则 localStorage key 和路径都错误
- 2026-05-18：Phase 4 超时强制停止后，项目代码已生成但未部署，下次应能继续从 build 开始
- 2026-05-18：playwright-mcp 存在进程泄漏问题，禁止在自动化流程（凌晨孵化）中使用，只能手动调试
- 2026-05-18：依赖 Skill 中移除 playwright-mcp，只保留 ui-ux-pro-max 和 openclaw-tavily-search

---

## Showcase 网站

- 2026-05-18：Showcase 网站 `/showcase/`，用于展示所有孵化项目
- 2026-05-18：数据来源为 `projects/incubated/` 目录（隔离测试产物）
- 2026-05-18：SVG 卡片使用 Terminal + Neon 风格（深色背景 + 暖金发光 + 网格线）
- 2026-05-18：SVG 双尺寸策略
  - 首页卡片：361×170（匹配 Showcase 网格容器实际尺寸）
  - 弹窗大图：511×220（匹配弹窗截图区实际尺寸）
  - 使用 `generate-card-svg.sh {name} card|modal` 生成
- 2026-05-18：chromium snap 在 `/root/` 路径下有 AppArmor 限制（无法写 /root/.openclaw/），截图脚本用 `/root/screenshot-tmp` 作为临时目录
- 2026-05-18：SVG 内文字用 Georgia 衬线字体，与 Literary Dark 页面风格统一
- 2026-05-18：每个新项目 deploy 后自动生成 SVG + 更新 projects.json

## 子 agent 报告规范

- 2026-05-18：runner.sh deploy 成功后写入 `PRODUCTION_URL=https://openginko.tech/{project}/` 到日志
- 2026-05-18：子 agent 报告交付地址时必须从日志解析，禁止硬编码 `http://localhost/`