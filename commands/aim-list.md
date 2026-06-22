---
name: aim-list
description: List all projects managed by ai-memory on this machine. Scans known root directories and distributed project markers. Read-only overview.
---

# /aim-list — List All Projects

## Purpose

Show all projects on this machine that have been initialized with ai-memory. Helps users:
- Recall where project memories live
- Switch context between projects
- Audit which projects use ai-memory

Typical use cases:
- Forgot where a project's memory is stored
- Want an overview of ai-memory usage
- Setting up a new machine and checking what is initialized

## Usage

```
/aim-list [--mode <central|distributed|all>]
```

- No arguments: list all (default).
- `--mode central`: list only centralized projects.
- `--mode distributed`: list only distributed projects.

## Prerequisites

None.

## Workflow

### Step 1: Scan centralized projects

Read `~/.claude/ai-memory/projects.json` (the registry of known roots).

For each registered root:
1. List subdirectories.
2. For each subdirectory, check if `INDEX.yaml` exists.
3. If it does, parse and extract: project name, mode, creation date, document count.

Also scan the default root `~/Desktop/persistent-document/` even if it is not in the registry.

### Step 2: Scan distributed projects

Walk common code directories looking for `.ai-memory/INDEX.yaml`:

Default scan locations:
- `~/Desktop/`
- `~/Documents/`
- `~/Projects/` (if it exists)
- `~/code/` (if it exists)
- `~/dev/` (if it exists)

Depth limit of 3 levels to avoid scanning the entire filesystem.

For each `.ai-memory/INDEX.yaml` found:
1. Parse it.
2. Extract project information.
3. Record the absolute path.

### Step 3: Resolve identity for each project

For each project's `initialized_by.id`, attempt to resolve to a name:
- Check `~/.claude/ai-memory/identity.json` (if it matches the current user).
- Otherwise, show the raw ID.

### Step 4: Calculate summary statistics

For each project:
- Active document count + total tokens
- Compressed document count + tokens
- Snapshot count
- Most recent update date
- Days since last activity

### Step 5: Sort and group

Sort by most recently updated (newest first).

If `--mode` is not specified, group by mode (centralized vs. distributed).

### Step 6: Output

```
📋 ai-memory Project List (4 projects)

🗂️ Centralized (3)
  1. Video Project
     📁 /Users/.../persistent-document/bauto-video
     📊 Active 6 / Compressed 1 / Snapshots 2 | 21,000 tokens
     📅 Last updated: 2026-06-21 (today)
     👤 Initialized by: Zhu Taofeng (u-a3b2f1c9)

  2. Assistant Project
     📁 /Users/.../persistent-document/cf-zs-rn
     📊 Active 3 / Compressed 0 / Snapshots 1 | 5,200 tokens
     📅 Last updated: 2026-06-18 (3 days ago)
     👤 Initialized by: Zhu Taofeng (u-a3b2f1c9)

  3. Card Project
     📁 /Users/.../persistent-document/baby-card-app
     📊 Active 12 / Compressed 2 / Snapshots 4 | 45,000 tokens
     ⚠️ Last updated: 2026-05-10 (42 days ago, possibly stale)
     👤 Initialized by: Zhu Taofeng (u-a3b2f1c9)

📂 Distributed (1)
  4. open-source-tool
     📁 /Users/.../projects/open-source-tool/.ai-memory
     📊 Active 2 / Compressed 0 / Snapshots 0 | 1,800 tokens
     📅 Last updated: 2026-06-20 (yesterday)
     👤 Initialized by: Zhu Taofeng (u-a3b2f1c9)

💡 Tips
  - Card Project not updated in 42 days — consider /aim-archive
  - Total across all projects: 73,000 tokens
```

## Edge Cases

### Case A: No initialized projects at all

```
📋 ai-memory Project List

No projects initialized yet.
Run /aim-init <project-name> to get started.
```

### Case B: INDEX.yaml in a project directory is corrupted

- Skip that project in the listing.
- Note at the end: `⚠️ Project [xxx] has a corrupted INDEX.yaml — suggest running /aim-rebuild.`

### Case C: Scan discovers projects not in the projects.json registry

- Automatically add to the registry (centralized mode).
- Mark in output: `(newly discovered, added to registry)`.

### Case D: Filesystem scan is slow (large home directory)

- 5-second timeout per top-level directory.
- Note: `Scan timed out — some distributed projects may have been missed.`

### Case E: A distributed project has `.ai-memory/` but no INDEX.yaml

- Appears to be a half-initialized project.
- Note: `⚠️ [xxx] has .ai-memory/ but no INDEX.yaml — initialization may be incomplete.`

## Output Style

- All labels in English.
- Group by mode with section headings (🗂️ Centralized / 📂 Distributed).
- Per project: number, name, path, stats, date, owner.
- Use ⚠️ for stale (>30 days) or corrupted projects.
- Truncate long paths with `...` in the middle.
- Always show the total token count at the end.

## Soft Sandbox Behavior

- Public command — no restrictions.
- Shows all projects regardless of who initialized them (this is a machine-level inventory).

## References

- Reads `~/.claude/ai-memory/projects.json` for centralized roots.
- Companion commands: `/aim-init`, `/aim-status`, `/aim-uninit`
