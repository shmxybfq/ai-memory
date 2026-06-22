---
name: aim-help
description: Display built-in help for all ai-memory commands. Lists usage, prerequisites, and links to detailed docs for each command. Read-only.
---

# /aim-help — Built-in Help

## Purpose

Display help for all ai-memory commands. Acts as an in-conversation reference manual so users can look up syntax without leaving Claude Code.

Use cases:
- First time using ai-memory
- Forgot the exact syntax for a command
- Want to discover commands you haven't used yet

## Usage

```
/aim-help [command-name]
```

- No arguments: display all commands grouped by category.
- With a command name (e.g. `/aim-help aim-add`): show detailed help for that command.

## Prerequisites

None. Always available.

## Workflow

### Step 1: Determine output mode

- If the argument matches a known command name (e.g. `aim-add`, `aim-init`): **single-command mode**.
- If no argument or unrecognized: **overview mode**.

### Step 2: Overview mode — render command catalog

Read all `commands/*.md` files in the Skill directory. Extract from each file:
- `name` and `description` from the frontmatter.
- Usage line from the `## Usage` section.
- Sandbox badge (from the table in SKILL.md).

Group by category:

| Category | Commands |
|---|---|
| 🚀 Getting Started | `/aim-init`, `/aim-help`, `/aim-identity` |
| 📝 Daily Notes | `/aim-add`, `/aim-append`, `/aim-edit`, `/aim-archive` |
| 🗜️ Compress & Archive | `/aim-compress`, `/aim-expand` |
| 🔍 Status & Maintenance | `/aim-status`, `/aim-verify`, `/aim-rebuild` |
| 🛠️ Management | `/aim-list`, `/aim-uninit` |

Render output (see Output Style).

### Step 3: Single-command mode — render details

Look up `commands/<name>.md`. Extract:
- Purpose (opening paragraph).
- Usage with all flags.
- Prerequisites.
- Quick example.

Display as a focused help card.

### Step 4: Output

#### Overview output

```
📖 ai-memory Command Help

ai-memory gives Claude Code cross-session project memory capabilities.
To get started, run: /aim-init

🚀 Getting Started
  /aim-init [project-name]          Initialize project memory (once per project)
  /aim-help [command-name]          Show this help
  /aim-identity                     View or modify user identity

📝 Daily Notes
  /aim-add [content]                Add a new document (always creates new)
  /aim-append <doc_id>              Append a section to an existing document
  /aim-edit <doc_id>                Edit an existing document
  /aim-archive <doc_id>             Archive a document to a snapshot

🗜️ Compress & Archive
  /aim-compress [--dry-run]         Merge active documents into a compressed doc
  /aim-expand <doc_id>              Expand details back from a snapshot

🔍 Status & Maintenance
  /aim-status                       View project status (tokens, git, health)
  /aim-verify [--fix]               Consistency check
  /aim-rebuild [--dry-run]          Rebuild INDEX.yaml from the filesystem

🛠️ Management
  /aim-list                         List all ai-memory projects
  /aim-uninit                       Uninstall Skill (preserves user data)

💡 Tips
  - Most commands support natural language arguments
  - Type /aim-help <command-name> for details on a single command
  - Example: /aim-help aim-add
```

#### Single-command output

```
📖 /aim-add — Add a New Document

Purpose
  Create a new HTML document in project memory. Always creates a new file,
  never modifies an existing one. Use /aim-append to extend, /aim-edit to modify.

Usage
  /aim-add [natural language content or description]

  - With argument: use it directly as content
  - Without argument: prompt the user for input

Prerequisites
  - Project has been initialized (/aim-init has been run)
  - User identity has been established

Example
  /aim-add We discussed the auth module approach today, going with JWT + Refresh Token...
  /aim-add (then wait for the prompt)

Related Commands
  /aim-append, /aim-edit, /aim-status

Full docs: commands/aim-add.md
```

## Edge Cases

### Case A: Command name not found

- Output: `Unknown command [xxx]. Run /aim-help (no arguments) to see all commands.`

### Case B: User asks for help via natural language

- e.g. `/aim-help how to add document` — identify the intent and route to `aim-add`.

### Case C: commands directory missing or empty

- Should not happen with a proper installation.
- If it does: report `Skill installation incomplete — commands directory missing. Please reinstall.`

## Output Style

- Write entirely in English.
- Use emoji headers to group commands (🚀 📝 🗜️ 🔍 🛠️).
- One line per command with a usage hint.
- Keep the overview to 25 lines or fewer (one screen).
- Single-command view uses section headers (Purpose / Usage / Prerequisites / Example / Related Commands).

## Soft Sandbox Behavior

- Public command — no restrictions.

## References

- Auto-discovered from `commands/*.md`.
- Cross-references SKILL.md for the sandbox table.
