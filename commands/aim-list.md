---
name: aim-list
description: List all projects managed by ai-memory on this machine. Scans known roots and distributed project markers. Read-only overview.
---

# /aim-list — List All Projects

## Purpose

Show every project on this machine that has ai-memory initialized. Helps users:
- Remember where their projects live
- Switch context between projects
- Audit which projects are using ai-memory

Use this command when:
- You forget where a project's memory is stored
- You want an overview of your ai-memory usage
- Setting up a new machine and checking what's been initialized

## Usage

```
/aim-list [--mode <central|distributed|all>]
```

- No argument: list all (default).
- `--mode central`: only central-mode projects.
- `--mode distributed`: only distributed-mode projects.

## Prerequisites

None.

## Flow

### Step 1: Scan Central Mode Projects

Read `~/.claude/ai-memory/projects.json` (registry of known roots).

For each registered root:
1. List subdirectories.
2. For each subdir, check if `INDEX.yaml` exists.
3. If yes, parse it, extract: project name, mode, created date, doc counts.

Also scan default root `~/Desktop/persistent-document/` even if not in registry.

### Step 2: Scan Distributed Mode Projects

Walk common code directories looking for `.ai-memory/INDEX.yaml`:

Default scan locations:
- `~/Desktop/`
- `~/Documents/`
- `~/Projects/` (if exists)
- `~/code/` (if exists)
- `~/dev/` (if exists)

Limit depth to 3 levels to avoid scanning the entire filesystem.

For each found `.ai-memory/INDEX.yaml`:
1. Parse it.
2. Extract project info.
3. Note absolute path.

### Step 3: Resolve Identity for Each Project

For each project's `initialized_by.id`, try to resolve to a name:
- Check `~/.claude/ai-memory/identity.json` (if it matches current user).
- Otherwise show raw ID.

### Step 4: Compute Summary Stats

For each project:
- Active doc count + total tokens
- Compressed doc count + tokens
- Snapshot count
- Last updated date
- Days since last activity

### Step 5: Sort and Group

Sort by last updated (most recent first).

Group by mode (central vs distributed) if `--mode` not specified.

### Step 6: Output

```
📋 ai-memory 项目清单 (共 4 个项目)

🗂️ 集中式 (3 个)
  1. 视频项目
     📁 /Users/.../persistent-document/bauto-video
     📊 活跃 6 / 压缩 1 / 快照 2 | 21,000 tokens
     📅 最近更新: 2026-06-21 (今天)
     👤 初始化: 朱陶锋 (u-a3b2f1c9)

  2. 助手项目
     📁 /Users/.../persistent-document/cf-zs-rn
     📊 活跃 3 / 压缩 0 / 快照 1 | 5,200 tokens
     📅 最近更新: 2026-06-18 (3 天前)
     👤 初始化: 朱陶锋 (u-a3b2f1c9)

  3. 卡片项目
     📁 /Users/.../persistent-document/baby-card-app
     📊 活跃 12 / 压缩 2 / 快照 4 | 45,000 tokens
     ⚠️ 最近更新: 2026-05-10 (42 天前,可能已停滞)
     👤 初始化: 朱陶锋 (u-a3b2f1c9)

📂 分散式 (1 个)
  4. open-source-tool
     📁 /Users/.../projects/open-source-tool/.ai-memory
     📊 活跃 2 / 压缩 0 / 快照 0 | 1,800 tokens
     📅 最近更新: 2026-06-20 (昨天)
     👤 初始化: 朱陶锋 (u-a3b2f1c9)

💡 提示
  - 卡片项目 42 天未更新,考虑 /aim-archive 归档
  - 总计 73,000 tokens 在所有项目中
```

## Edge Cases

### Case A: No projects initialized at all

```
📋 ai-memory 项目清单

尚未初始化任何项目。
运行 /aim-init <项目名> 开始。
```

### Case B: INDEX.yaml in a project dir is corrupted

- Skip that project in the list.
- Note at the end: `⚠️ 项目 [xxx] 的 INDEX.yaml 损坏,建议运行 /aim-rebuild`。

### Case C: Scan finds projects not in projects.json registry

- Add them to the registry automatically (central mode).
- Note in output: `(本次新发现,已加入注册表)`。

### Case D: Filesystem scan is slow (huge home directory)

- Timeout after 5 seconds per top-level dir.
- Note: `扫描超时,可能遗漏部分分散式项目`。

### Case E: Distributed project's `.ai-memory/` exists but INDEX.yaml missing

- Looks like a half-initialized project.
- Note: `⚠️ [xxx] 有 .ai-memory/ 但无 INDEX.yaml,可能初始化未完成`。

## Output Style

- Use Chinese throughout.
- Group by mode with section headers (🗂️ 集中式 / 📂 分散式).
- Each project: number, name, path, stats, date, owner.
- Use ⚠️ for stale (>30 days) or corrupted projects.
- Truncate long paths with `...` in the middle.
- Always show total token sum at the end.

## Soft Sandbox Behavior

- Public command — no restrictions.
- Shows all projects regardless of who initialized them (this is a machine-wide inventory).

## Reference

- Reads `~/.claude/ai-memory/projects.json` for central-mode roots.
- Companion commands: `/aim-init`, `/aim-status`, `/aim-uninit`
