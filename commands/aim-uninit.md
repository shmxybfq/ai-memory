---
name: aim-uninit
description: Remove ai-memory Skill injections from a project. Keeps all user data (docs, snapshots, INDEX.yaml). Reversible by re-running /aim-init.
---

# /aim-uninit — Remove Skill Injections

## Purpose

Remove ai-memory's footprint from a project without deleting user data. Specifically:
- Strips the ai-memory rules block from `CLAUDE.md` (between markers).
- Removes project entry from `~/.claude/ai-memory/projects.json` (central mode).
- Keeps all documents, snapshots, INDEX.yaml, compressed docs intact.

Use this command when:
- You want to stop using ai-memory on a specific project
- You're handing off a project and want to clean up
- You want to reset and re-initialize from scratch (alternative: delete INDEX.yaml manually)

**Reversible**: re-running `/aim-init` on the same project will redetect existing data and re-inject rules.

## Usage

```
/aim-uninit [--project <name|path>] [--purge] [--global]
```

- No argument: uninit the current project (resolved from cwd).
- `--project <name>`: uninit a specific project by name or path.
- `--purge`: **also delete user data** (docs, snapshots, INDEX.yaml). DANGEROUS. Requires double confirmation.
- `--global`: uninstall the Skill entirely (removes `~/.claude/skills/ai-memory/` or symlink). Does not touch any project data.

## Prerequisites

For project-level uninit:
- Project must be currently initialized (rules in CLAUDE.md, entry in projects.json).

For global uninstall:
- Skill must be installed at `~/.claude/skills/ai-memory/`.

## Flow

### Step 1: Determine Scope

Parse flags:
- `--global` → skip to Step 8 (global uninstall).
- `--purge` → enable destructive mode (Step 7).
- Otherwise: project-level uninit.

### Step 2: Resolve Target Project

If `--project` provided:
- Match by name (lookup in projects.json).
- Or match by path prefix.

Otherwise: resolve from cwd (same logic as `/aim-add` Step 1).

If no project found: `当前目录不在任何 ai-memory 项目中,无需卸载`。

### Step 3: Show What Will Be Removed

Before any changes, show a clear preview:

```
⚠️ 即将从项目 [视频项目] 移除 ai-memory

将删除:
  - CLAUDE.md 中的 ai-memory 规则块(位于 <!-- ai-memory rules start --> 与 end 标记之间)
  - projects.json 中的项目注册条目

将保留:
  - 所有文档: ~/Desktop/persistent-document/bauto-video/*.html (6 篇)
  - 压缩文档: compressed-20260621.html
  - 快照: snapshots/ (2 个目录)
  - INDEX.yaml(可在重新 /aim-init 时复用)

确认卸载? (Y/n)
```

Wait for explicit confirmation. Default n.

### Step 4: Strip CLAUDE.md Rules

Read CLAUDE.md. Locate the ai-memory rules block:

```
<!-- ai-memory rules start -->
... (rules content) ...
<!-- ai-memory rules end -->
```

Remove the block including the markers. Preserve everything else in CLAUDE.md.

Edge cases:
- If markers not found: note `CLAUDE.md 中未找到 ai-memory 规则,跳过此步`。
- If CLAUDE.md doesn't exist: skip.
- If after removal CLAUDE.md is empty or only whitespace: leave it as empty file (don't delete, user may have plans for it).

Backup CLAUDE.md to `CLAUDE.md.bak.<timestamp>` before edit.

### Step 5: Remove from projects.json

Read `~/.claude/ai-memory/projects.json`. Remove the entry for this project's root.

If this was the last project under a root, optionally remove the root entry too.

Write back. Backup first.

### Step 6: Leave Data Intact

Explicitly do NOT touch:
- `<root>/*.html` (active docs)
- `<root>/compressed-*.html`
- `<root>/snapshots/`
- `<root>/INDEX.yaml`
- `~/.claude/ai-memory/identity.json` (global, not project-specific)

### Step 7: Purge Mode (only if --purge)

If `--purge` flag set, after Step 3 confirmation, ask again with stronger warning:

```
🚨 危险操作确认 🚨

你选择了 --purge,这会永久删除项目所有数据:
  - 6 篇活跃文档
  - 1 篇压缩文档
  - 2 个快照目录(14 篇归档)
  - INDEX.yaml

此操作不可恢复(除非有 Git 历史或外部备份)。

请输入项目名「视频项目」以确认彻底删除:
> _
```

User must type the exact project name. If mismatch: abort.

On confirm:
1. Move entire project memory dir to `~/.Trash/ai-memory-purge-<project>-<timestamp>/` (macOS Trash, recoverable for 30+ days).
2. Do NOT `rm -rf` directly — always go through Trash.
3. Remove from projects.json (already done in Step 5).

### Step 8: Global Uninstall (only if --global)

If `--global`:

```
⚠️ 全局卸载 ai-memory Skill

将从以下位置移除 Skill 本体:
  - ~/.claude/skills/ai-memory/ (或 symlink)

不会修改任何项目数据。
但所有 /aim-* 命令将不再可用。

确认全局卸载? (Y/n)
```

On confirm:
1. If `~/.claude/skills/ai-memory` is a symlink: just remove the symlink.
2. If it's a real directory: move to Trash (recoverable).
3. Keep `~/.claude/ai-memory/` (user data: identity, projects.json) — that's data, not Skill.

### Step 9: Output

#### Project-level uninit (no --purge)

```
✅ ai-memory 已从项目 [视频项目] 移除

📋 移除内容
  - CLAUDE.md: 已移除 ai-memory 规则块(备份在 CLAUDE.md.bak.20260621-153022)
  - projects.json: 已移除该项目条目

📁 保留的数据(随时可重新初始化)
  - 6 篇活跃文档
  - 1 篇压缩文档
  - 2 个快照目录
  - INDEX.yaml

📝 重新启用
  cd /Users/.../bauto-video
  /aim-init 视频项目
  (会自动检测并复用现有数据)
```

#### With --purge

```
✅ 项目 [视频项目] 已彻底清除

📋 已删除
  - 所有文档、压缩文档、快照、INDEX.yaml
  - 已移至废纸篓: ~/.Trash/ai-memory-purge-bauto-video-20260621-153022/
  - 30 天内可从废纸篓恢复

📝 重新开始
  /aim-init 视频项目
```

#### Global uninstall

```
✅ ai-memory Skill 已全局卸载

📋 移除内容
  - ~/.claude/skills/ai-memory/ (移至废纸篓)

📁 保留
  - ~/.claude/ai-memory/ (用户数据:identity.json, projects.json)
  - 各项目的文档与 INDEX.yaml

📝 重新安装
  git clone https://github.com/shmxybfq/ai-memory ~/.claude/skills/ai-memory
```

## Edge Cases

### Case A: Project not initialized (no markers in CLAUDE.md, no projects.json entry)

- Output: `项目 [xxx] 未启用 ai-memory,无需卸载`。

### Case B: CLAUDE.md is read-only

- Error: `无法修改 CLAUDE.md,请检查文件权限`。
- Suggest: `sudo chown $(whoami) CLAUDE.md` or manual edit.

### Case C: projects.json corrupted

- Skip that step.
- Note: `projects.json 解析失败,请手动清理项目条目`。

### Case D: --purge on a project with no data (only CLAUDE.md injection)

- Just remove the injection.
- Note: `项目无实际数据,仅清理 CLAUDE.md`。

### Case E: User tries --purge --global together

- Block: `--purge 与 --global 不可同时使用。--global 仅移除 Skill 本体,--purge 针对单个项目数据`。

### Case F: macOS Trash is unavailable (Linux/non-Mac)

- Fall back to `~/.ai-memory-trash/<timestamp>/` directory.
- Note this location in output.

## Output Style

- Use Chinese throughout.
- Use ⚠️ for irreversible/dangerous steps.
- Use 🚨 for purge mode.
- Always show backups and Trash paths.
- End with 📝 重新开始/重新启用 section showing recovery path.

## Soft Sandbox Behavior

- Uninit is a **destructive administrative operation**.
- For multi-user projects, require confirmation from project owner (or anyone if owner unknown).
- `--purge` requires the project-name-typing confirmation regardless of user.

## Reference

- Companion commands: `/aim-init` (reverse operation)
- Concept: "Skill body and user data completely separated" (Design Principle 5 in SKILL.md)
