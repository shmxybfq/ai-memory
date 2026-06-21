---
name: ai-memory
description: Claude Code 的跨会话项目记忆层。提供文档沉淀、压缩、归档与检索能力。安装一次,即可获得跨会话的持久项目知识。
version: 0.1.0
author: ai-memory
license: MIT
---

# ai-memory

> AI 编程助手的跨会话记忆层 — 每次新会话,AI 无需重新探索你的项目,可直接读取你累积的项目知识。

## 这个 Skill 做什么

`ai-memory` 让 Claude Code 在跨会话间拥有持久的项目记忆。Claude 不再每次重新探索项目,而是直接读取你累积的知识。

**核心能力:**
- 📝 文档沉淀(`/aim-add`)
- 🗜️ 双区智能压缩(当前有效 + 历史归档)(`/aim-compress`)
- 📊 状态监控(`/aim-status`)
- 🔍 从快照反向检索(`/aim-expand`)
- 👥 软沙盒多用户协作
- 🧹 自动重建与校验

## 命令

| 命令 | 用途 | 沙盒 |
|---|---|---|
| `/aim-init` | 初始化项目记忆(一次性) | ❌ |
| `/aim-add` | 添加新文档(总是创建新文件) | ✅ |
| `/aim-append` | 向已有文档追加章节 | ✅ |
| `/aim-edit` | 修改已有文档 | ✅ |
| `/aim-archive` | 把文档归档到快照 | ✅ |
| `/aim-compress` | 把活跃文档压缩为双区单文件(MVP 单步 + 规则校验) | ⚠️ 特殊 |
| `/aim-status` | 显示项目状态、token 使用、Git 漂移 | ❌ |
| `/aim-rebuild` | 从文件系统重建 INDEX.yaml | ❌ |
| `/aim-verify` | 检查 INDEX.yaml 与文件系统一致性 | ❌ |
| `/aim-expand` | 反向搜索快照获取细节 | ❌ |
| `/aim-list` | 列出所有 ai-memory 项目 | ❌ |
| `/aim-help` | 显示所有命令的帮助 | ❌ |
| `/aim-uninit` | 移除 Skill 注入(保留用户数据) | ❌ |
| `/aim-identity` | 查看或修改用户身份 | ❌ |

各命令的详细流程见 `commands/` 目录。

## 核心概念

### 两种存储模式

- **集中式模式(默认)**:所有项目共享一个文档根(如 `~/Desktop/persistent-document/`)。一个 CLAUDE.md 管理所有项目。适合管理多个私有项目的个人。
- **分散式模式**:每个项目在自己的代码库内嵌入 `.ai-memory/`。适合团队协作和开源。

### 软沙盒(多用户协作)

每个用户拥有全局身份(`~/.claude/ai-memory/identity.json`)。默认情况下,用户只能直接修改自己的文档。跨用户操作**每次**都需显式确认(不做缓存)。

### 文档生命周期

```
/aim-add  →  memory/*.html  →  /aim-compress  →  snapshots/YYYY-MM-DD/
                                  ↓
                          compressed.html
                  (双区:活跃 + 归档)
```

### 双区压缩

压缩文档有两个固定区:
- **活跃区**:当前有效知识(AI 优先读取)
- **归档区**:标记为 `[deprecated]` 的弃用内容(软删除,不移除)

这样既防止膨胀,又不丢失信息。

### 元数据嵌入

每个文档在顶部 HTML 注释中有元数据:
```html
<!-- aim:doc_id=aim-20260610-a3b2f1 title=... tags=... created=... created_by=... owner=... status=... -->
```

INDEX.yaml 是**可重建的缓存**,不是事实源。文件系统才是事实源。

## 使用流程

### 首次使用
```
1. /aim-init [project-name]
   → 选择模式(集中式/分散式)
   → 选择文档根路径
   → 生成 INDEX.yaml
   → 把规则注入 CLAUDE.md(追加,不覆盖)

2. /aim-add [自然语言描述]
   → Claude 把内容结构化为 HTML
   → 嵌入元数据头
   → 更新 INDEX.yaml

3. /aim-status
   → 验证设置已生效
```

### 日常工作流
```
/aim-add       → 记录知识(随时)
/aim-status    → 检查状态(偶尔)
/aim-compress  → 攒到 3-5 篇时压缩
```

## 架构

```
ai-memory/
├── SKILL.md                  ← 本文件(入口)
├── commands/                 ← 每个斜杠命令一个 .md
├── prompts/                  ← 留待 v0.2(MVP 阶段为空目录)
├── templates/                ← 文件模板
│   ├── INDEX.yaml.tpl
│   ├── claude-md-rules.md.tpl
│   ├── doc-template.html.tpl
│   └── compressed-template.html.tpl
└── reference/                ← 内部参考文档
```

## 版本

当前:`0.1.0`(MVP)

版本历史见 CHANGELOG.md。Skill 启动时检查 GitHub 是否有更新,并在有新版本时提示用户。

## 设计原则

1. **文件系统是事实源** — INDEX.yaml 是可重建缓存
2. **软约束优于硬权限** — 用确认代替阻断
3. **保守压缩** — 宁可保留也不丢失
4. **基于规则的校验** — 用正则提取硬信息,不信任 LLM 自检
5. **Skill 本体与用户数据完全分离** — 卸载保留数据

## 参考文档

- `reference/upgrade-check.md` — 升级检查机制(非阻塞、每日一次)

> 更多参考文档(文档生命周期、压缩流水线细节、模式对比、软沙盒等)将在 v0.2 版本补充。

## License

MIT
