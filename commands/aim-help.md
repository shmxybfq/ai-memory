---
name: aim-help
description: Show built-in help for all ai-memory commands. Lists every command with usage, prerequisites, and links to detailed docs. Read-only.
---

# /aim-help — Built-in Help

## Purpose

Display help for all ai-memory commands. Acts as an in-conversation manual so users don't need to leave Claude Code to look up syntax.

Use when:
- First time using ai-memory
- Forgot exact syntax of a command
- Want to discover commands you haven't used

## Usage

```
/aim-help [command-name]
```

- No argument: show all commands grouped by category.
- With command name (e.g., `/aim-help aim-add`): show detailed help for that specific command.

## Prerequisites

None. Always works.

## Flow

### Step 1: Determine Output Mode

- If argument matches a known command name (e.g., `aim-add`, `aim-init`): **single-command mode**.
- If no argument or unrecognized: **overview mode**.

### Step 2: Overview Mode — Render Command Catalog

Read all `commands/*.md` files in the Skill directory. Extract from each:
- `name` and `description` from frontmatter.
- Usage line from the `## Usage` section.
- Sandbox badge (from the table in SKILL.md).

Group by category:

| Category | Commands |
|---|---|
| 🚀 入门 | `/aim-init`, `/aim-help`, `/aim-identity` |
| 📝 日常记录 | `/aim-add`, `/aim-append`, `/aim-edit`, `/aim-archive` |
| 🗜️ 压缩归档 | `/aim-compress`, `/aim-expand` |
| 🔍 状态与维护 | `/aim-status`, `/aim-verify`, `/aim-rebuild` |
| 🛠️ 管理 | `/aim-list`, `/aim-uninit` |

Render output (see Output Style).

### Step 3: Single-Command Mode — Render Detail

Find `commands/<name>.md`. Extract:
- Purpose (first paragraph).
- Usage with all flags.
- Prerequisites.
- Quick example.

Display as a focused help card.

### Step 4: Output

#### Overview Output

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

#### Single-Command Output

```
📖 /aim-add — 添加新文档

用途
  在项目记忆中创建新的 HTML 文档。总是新建文件,
  从不修改已有文档。用 /aim-append 扩展,用 /aim-edit 修改。

用法
  /aim-add [natural language content or description]

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

## Edge Cases

### Case A: Command name not found

- Output: `未知命令 [xxx]。运行 /aim-help(无参数)查看所有命令列表`。

### Case B: User asks for help on a command via natural language

- e.g., `/aim-help how to add document` → recognize intent, route to `aim-add`.

### Case C: Commands directory missing or empty

- Should never happen in normal install.
- If it does: error `Skill 安装不完整,commands 目录缺失。请重新安装`。

## Output Style

- Use Chinese throughout.
- Group commands with emoji headers (🚀 📝 🗜️ 🔍 🛠️).
- Each command on one line with usage hint.
- Keep overview under 25 lines (one screen).
- For single-command view, use sections with headers (用途/用法/前置条件/示例/相关命令).

## Soft Sandbox Behavior

- Public command — no restrictions.

## Reference

- Auto-discovers from `commands/*.md`.
- Cross-references SKILL.md for the sandbox table.
