---
name: aim-help
description: 显示所有 ai-memory 命令的内置帮助。列出每个命令的用法、前置条件和详细文档链接。只读。
---

# /aim-help — 内置帮助

## 用途

显示所有 ai-memory 命令的帮助。作为对话内的手册,用户无需离开 Claude Code 即可查询语法。

适用场景:
- 首次使用 ai-memory
- 忘了某个命令的确切语法
- 想发现还没用过的命令

## 用法

```
/aim-help [command-name]
```

- 无参数:按类别分组展示所有命令。
- 带命令名(如 `/aim-help aim-add`):显示该命令的详细帮助。

## 前置条件

无。始终可用。

## 流程

### 步骤 1:确定输出模式

- 如果参数匹配已知命令名(如 `aim-add`、`aim-init`):**单命令模式**。
- 如果无参数或无法识别:**概览模式**。

### 步骤 2:概览模式 — 渲染命令目录

读取 Skill 目录下所有 `commands/*.md` 文件。从每个文件提取:
- frontmatter 中的 `name` 和 `description`。
- `## 用法` 章节中的用法行。
- 沙盒徽章(来自 SKILL.md 中的表)。

按类别分组:

| 类别 | 命令 |
|---|---|
| 🚀 入门 | `/aim-init`、`/aim-help`、`/aim-identity` |
| 📝 日常记录 | `/aim-add`、`/aim-append`、`/aim-edit`、`/aim-archive` |
| 🗜️ 压缩归档 | `/aim-compress`、`/aim-expand` |
| 🔍 状态与维护 | `/aim-status`、`/aim-verify`、`/aim-rebuild` |
| 🛠️ 管理 | `/aim-list`、`/aim-uninit` |

渲染输出(见输出风格)。

### 步骤 3:单命令模式 — 渲染详情

查找 `commands/<name>.md`。提取:
- 用途(首段)。
- 含所有 flag 的用法。
- 前置条件。
- 快速示例。

作为聚焦的帮助卡片展示。

### 步骤 4:输出

#### 概览输出

```
📖 ai-memory 命令帮助

ai-memory 让 Claude Code 拥有跨会话的项目记忆能力。
首次使用请运行: /aim-init

🚀 入门
  /aim-init [项目名]            初始化项目记忆(每个项目仅一次)
  /aim-help [命令名]            显示本帮助
  /aim-identity                 查看/修改用户身份

📝 日常记录
  /aim-add [内容]               添加新文档(总是新建)
  /aim-append <doc_id>          在现有文档后追加章节
  /aim-edit <doc_id>            修改现有文档
  /aim-archive <doc_id>         归档文档到快照

🗜️ 压缩归档
  /aim-compress [--dry-run]     合并活跃文档为压缩文档
  /aim-expand <doc_id>          从快照反向展开细节

🔍 状态与维护
  /aim-status                   查看项目状态(token、Git、健康度)
  /aim-verify [--fix]           一致性检查
  /aim-rebuild [--dry-run]      从文件系统重建 INDEX.yaml

🛠️ 管理
  /aim-list                     列出所有 ai-memory 项目
  /aim-uninit                   卸载 Skill(保留用户数据)

💡 提示
  - 大多数命令支持中文参数
  - 输入 /aim-help <命令名> 查看单个命令详情
  - 例: /aim-help aim-add
```

#### 单命令输出

```
📖 /aim-add — 添加新文档

用途
  在项目记忆中创建新的 HTML 文档。总是新建文件,
  从不修改已有文档。用 /aim-append 扩展,用 /aim-edit 修改。

用法
  /aim-add [自然语言内容或描述]

  - 提供参数:直接使用作为内容
  - 无参数:提示用户输入

前置条件
  - 项目已初始化(/aim-init 已运行)
  - 用户身份已建立

示例
  /aim-add 我们今天讨论了认证模块的方案,采用 JWT + Refresh Token...
  /aim-add(然后等待提示)

相关命令
  /aim-append, /aim-edit, /aim-status

完整文档: commands/aim-add.md
```

## 边界情况

### 情况 A:命令名未找到

- 输出:`未知命令 [xxx]。运行 /aim-help(无参数)查看所有命令列表`。

### 情况 B:用户通过自然语言求助某命令

- 如 `/aim-help how to add document` → 识别意图,路由到 `aim-add`。

### 情况 C:commands 目录缺失或为空

- 正常安装下不应发生。
- 如发生:报错 `Skill 安装不完整,commands 目录缺失。请重新安装`。

## 输出风格

- 全程中文。
- 用 emoji 标题分组命令(🚀 📝 🗜️ 🔍 🛠️)。
- 每个命令一行,带用法提示。
- 概览保持在 25 行以内(一屏)。
- 单命令视图用章节标题(用途/用法/前置条件/示例/相关命令)。

## 软沙盒行为

- 公共命令 — 无限制。

## 参考

- 自动从 `commands/*.md` 发现。
- 交叉引用 SKILL.md 获取沙盒表。
