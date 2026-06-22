---
name: aim-uninit
description: Remove ai-memory Skill injection from a project. Preserves all user data (documents, snapshots, INDEX.yaml). Re-run /aim-init to restore.
---

# /aim-uninit — Remove Skill Injection

## Purpose

Remove ai-memory's traces from a project without deleting user data. Specifically:
- Strip the ai-memory rules block (between markers) from `CLAUDE.md`.
- Remove the project entry from `~/.claude/ai-memory/projects.json` (centralized mode).
- Keep all documents, snapshots, INDEX.yaml, and compressed documents intact.

Use cases:
- Want to stop using ai-memory on a particular project
- Handing off a project and want to clean up
- Want to start fresh and re-initialize (alternative: manually delete INDEX.yaml)

**Reversible**: re-running `/aim-init` on the same project will detect existing data and re-inject the rules.

## Usage

```
/aim-uninit [--project <name|path>] [--purge] [--global]
```

- No arguments: uninstall from the current project (resolved from cwd).
- `--project <name>`: uninstall a specific project by name or path.
- `--purge`: **also delete user data** (documents, snapshots, INDEX.yaml). Dangerous. Requires double confirmation.
- `--global`: fully uninstall the Skill (remove `~/.claude/skills/ai-memory/` or symlink). Does not touch any project data.

## Prerequisites

Project-level uninstall:
- The project must currently be initialized (rules present in CLAUDE.md, entry present in projects.json).

Global uninstall:
- The Skill must be installed at `~/.claude/skills/ai-memory/`.

## Workflow

### Step 1: Determine scope

Parse flags:
- `--global` → jump to Step 8 (global uninstall).
- `--purge` → enable destructive mode (Step 7).
- Otherwise: project-level uninstall.

### Step 2: Resolve the target project

If `--project` is provided:
- Match by name (look up in projects.json).
- Or match by path prefix.

Otherwise: resolve from cwd (same logic as `/aim-add` Step 1).

If no project is found: `The current directory is not in any ai-memory project — nothing to uninstall.`

### Step 3: Show what will be removed

Before making changes, display a clear preview:

```
⚠️ About to remove ai-memory from project [video-project]

Will remove:
  - ai-memory rules block in CLAUDE.md (between <!-- ai-memory rules start --> and end markers)
  - project registration entry in projects.json

Will preserve:
  - All documents: ~/Desktop/persistent-document/bauto-video/*.html (6 files)
  - Compressed document: compressed-20260621.html
  - Snapshots: snapshots/ (2 directories)
  - INDEX.yaml (reusable on re-init)

Confirm uninstall? (Y/n)
```

Wait for explicit confirmation. Default to n.

### Step 4: Strip CLAUDE.md rules

Read CLAUDE.md. Locate the ai-memory rules block:

```
<!-- ai-memory rules start -->
... (rule content) ...
<!-- ai-memory rules end -->
```

Remove the block (including markers). Keep all other content in CLAUDE.md.

Edge cases:
- If markers are not found: note `No ai-memory rules found in CLAUDE.md — skipping this step.`
- If CLAUDE.md does not exist: skip.
- If CLAUDE.md is empty or whitespace-only after removal: keep as an empty file (do not delete — the user may have plans for it).

Back up CLAUDE.md before editing as `CLAUDE.md.bak.<timestamp>`.

### Step 5: Remove from projects.json

Read `~/.claude/ai-memory/projects.json`. Remove the entry for this project root.

If this is the last project under a given root, optionally remove the root entry too.

Write back. Back up first.

### Step 6: Leave user data untouched

Explicitly do not touch:
- `<root>/*.html` (active documents)
- `<root>/compressed-*.html`
- `<root>/snapshots/`
- `<root>/INDEX.yaml`
- `~/.claude/ai-memory/identity.json` (global, not project-specific)

### Step 7: Purge mode (only when --purge is set)

If `--purge` is set, after the Step 3 confirmation, ask again with a stronger warning:

```
🚨 Destructive Operation Confirmation 🚨

You chose --purge, which will permanently delete all project data:
  - 6 active documents
  - 1 compressed document
  - 2 snapshot directories (14 archived files)
  - INDEX.yaml

This operation is NOT recoverable (unless you have git history or external backups).

Please type the project name "video-project" to confirm full deletion:
> _
```

User must type the exact project name. Mismatch: abort.

After confirmation:
1. Move the entire project memory directory to `~/.Trash/ai-memory-purge-<project>-<timestamp>/` (macOS Trash, recoverable for 30+ days).
2. Never use `rm -rf` — always go through the Trash.
3. Remove from projects.json (already done in Step 5).

### Step 8: Global uninstall (only when --global is set)

If `--global`:

```
⚠️ Global Uninstall of ai-memory Skill

Will remove the Skill itself from:
  - ~/.claude/skills/ai-memory/ (or symlink)

Will NOT modify any project data.
However, all /aim-* commands will become unavailable.

Confirm global uninstall? (Y/n)
```

After confirmation:
1. If `~/.claude/skills/ai-memory` is a symlink: remove only the symlink.
2. If it is a real directory: move to Trash (recoverable).
3. Keep `~/.claude/ai-memory/` (user data: identity, projects.json) — that is data, not the Skill.
4. **Clean up `~/.claude/commands/aim-*.md` symlinks**: these were created by install.sh (to make `/aim-*` commands available in Claude Code). Check each `aim-*.md` — if it is a symlink pointing to the now-deleted skill directory, remove the symlink; if it is a real file (user-customized version), leave it alone.

### Step 9: Output

#### Project-level uninstall (without --purge)

```
✅ ai-memory removed from project [video-project]

📋 What was removed
  - CLAUDE.md: ai-memory rules block removed (backup at CLAUDE.md.bak.20260621-153022)
  - projects.json: project entry removed

📁 Preserved data (can re-initialize at any time)
  - 6 active documents
  - 1 compressed document
  - 2 snapshot directories
  - INDEX.yaml

📝 To re-enable
  cd /Users/.../bauto-video
  /aim-init video-project
  (will auto-detect and reuse existing data)
```

#### With --purge

```
✅ Project [video-project] fully purged

📋 Deleted
  - All documents, compressed documents, snapshots, INDEX.yaml
  - Moved to Trash: ~/.Trash/ai-memory-purge-bauto-video-20260621-153022/
  - Recoverable from Trash for 30 days

📝 To start over
  /aim-init video-project
```

#### Global uninstall

```
✅ ai-memory Skill globally uninstalled

📋 Removed
  - ~/.claude/skills/ai-memory/ (moved to Trash)

📁 Preserved
  - ~/.claude/ai-memory/ (user data: identity.json, projects.json)
  - All project documents and INDEX.yaml files

📝 To reinstall
  git clone https://github.com/shmxybfq/ai-memory ~/.claude/skills/ai-memory
```

## Edge Cases

### Case A: Project not initialized (no markers in CLAUDE.md, no entry in projects.json)

- Output: `Project [xxx] does not have ai-memory enabled — nothing to uninstall.`

### Case B: CLAUDE.md is read-only

- Error: `Cannot modify CLAUDE.md — check file permissions.`
- Suggestion: `sudo chown $(whoami) CLAUDE.md` or edit manually.

### Case C: projects.json is corrupted

- Skip this step.
- Note: `Failed to parse projects.json — please clean up the project entry manually.`

### Case D: --purge on a project with no data (only CLAUDE.md injection)

- Just remove the injection.
- Note: `Project has no actual data — only cleaning up CLAUDE.md.`

### Case E: User tries to combine --purge and --global

- Block: `--purge and --global cannot be used together. --global removes only the Skill itself; --purge targets a single project's data.`

### Case F: macOS Trash unavailable (Linux / non-Mac)

- Fall back to `~/.ai-memory-trash/<timestamp>/` directory.
- Note the fallback location in the output.

## Output Style

- Write entirely in English.
- Use ⚠️ for irreversible / dangerous steps.
- Use 🚨 for purge mode.
- Always show backup and Trash paths.
- End with a 📝 section for recovery / re-enable, showing the path forward.

## Soft Sandbox Behavior

- Uninstall is a **destructive management operation**.
- Multi-user projects require project owner confirmation (if the owner is unknown, anyone may confirm).
- `--purge` requires typing the project name regardless of who the user is.

## References

- Companion command: `/aim-init` (reverse operation)
- Concept: "Skill body and user data are fully separated" (SKILL.md design principle 5)
