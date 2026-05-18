# AI Incubator Project Skeleton

项目骨架模板，包含通用配置，可直接复制使用。

## 使用方法

```bash
cp -r /root/.openclaw/workspace/skills/ai-project-incubator/skeleton/ /root/.openclaw/workspace/projects/{project-name}/
cd /root/.openclaw/workspace/projects/{project-name}
```

## 包含内容

- `vite.config.ts` — 已有 `base: '/{project-name}/'`，只需改项目名
- `src/LanguageContext.tsx` — i18n Context，已包含切换按钮逻辑
- `src/i18n/en.ts` — 英文翻译（需填充）
- `src/i18n/zh.ts` — 中文翻译（需填充）
- `package.json` — 常用依赖 + deploy 脚本

## 复制后必做

1. 所有 `{project-name}` 替换为实际项目名（grep -r "project-name" .）
2. 填充 `src/i18n/en.ts` 和 `src/i18n/zh.ts` 翻译内容
3. 创建 `src/App.tsx` 和 `src/main.tsx`
4. 运行 `npm install`
5. 运行 `npm run dev` 验证

## 部署

```bash
npm run build && npm run deploy
```