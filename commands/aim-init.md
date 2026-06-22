---
name: aim-init
description: Initialize ai-memory for a project. Run once per project to set up the document structure, generate INDEX.yaml, and inject rules into CLAUDE.md.
---

# /aim-init — Initialize Project Memory

## Purpose

Set up ai-memory for a project. Creates the document structure, generates INDEX.yaml, and injects rules into CLAUDE.md so that Claude Code can discover and use project memory in future sessions.

**Run once per project.** Re-running on an already-initialized project is safe (it detects and skips).

## Usage

```
/aim-init [project-name]
```

- `project-name` (optional): A human-readable display name for the project (e.g. "Video Project"). If omitted, the user will be prompted.

## Prerequisites

- Claude Code must be installed.
- Centralized mode: you need to decide where all project documents will be stored at the root level.

## Workflow

Execute the following steps in order. Pause and prompt the user whenever input is required.

### Step 1: Resolve User Identity

Check whether a global identity already exists:

```
Read ~/.claude/ai-memory/identity.json
```

**If it exists**: use it as-is and skip to Step 2.

**If it does not exist**: create an identity.

1. Try to read the git global username:
   ```
   Run: git config --global user.name
   ```
2. If a git username is found, ask the user:
   ```
   Detected git username [John Doe]. Use it?
   1. Yes
   2. Enter a different name
   Choice (1/2):
   ```
3. If the git username is missing or the user chose option 2, ask:
   ```
   Enter your name (used to identify the author during collaboration):
   ```
4. Generate a user ID: `u-` + 8 random lowercase alphanumeric characters. Example: `u-a3b2f1c9`.
5. Determine the identity storage directory:
   - `~/.claude/ai-memory/` — create if it does not exist.
6. Write `~/.claude/ai-memory/identity.json`:
   ```json
   {
     "id": "u-a3b2f1c9",
     "name": "John Doe",
     "created": "2026-06-21",
     "git_user": "john-doe"
   }
   ```
7. Confirm to the user: `Identity created: John Doe (u-a3b2f1c9)`

### Step 2: Ask for Storage Mode

Ask the user:
```
Choose storage mode:
1. Centralized (recommended): all project documents live under one root directory, a single CLAUDE.md manages all projects
2. Distributed: each project has an embedded .ai-memory/ directory, documents travel with the code
Choice (1/2, default 1):
```

- Default: 1 (centralized)
- Store as `MODE` (central / distributed)

### Step 3: Resolve Document Root Directory

**Centralized mode**:
Ask the user for the root directory path:
```
Enter the document root directory path (default: ~/Desktop/persistent-document/):
```
- If empty, use `~/Desktop/persistent-document/`
- Expand `~` to the home directory
- Store as `ROOT_PATH`
- If the root directory does not exist, ask: `Path does not exist. Create it? (Y/n)`. Default Y.

**Distributed mode**:
- `ROOT_PATH` = current working directory (cwd)
- No prompt needed

### Step 4: Resolve Project Name and Subdirectory Name

**Project display name**:
- If provided as a command argument (e.g. `/aim-init Video Project`), use it directly.
- Otherwise, ask:
  ```
  Enter the project name (for display, e.g. "Video Project"):
  ```
- Store as `PROJECT_NAME`

**Subdirectory name** (filesystem name):

Ask the user:
```
Enter the project subdirectory name (for filesystem use, recommended: English/ASCII, e.g. "bauto-video"):
```
- Store as `SUBDIR_NAME`
- Validate: no spaces, no special characters except `-` and `_`
- If invalid, re-prompt

**Centralized mode**: project path = `ROOT_PATH / SUBDIR_NAME`
**Distributed mode**: project path = `ROOT_PATH / .ai-memory`

### Step 5: Check Whether the Project Already Exists

Read `<project_path>/INDEX.yaml`.

**If it exists**:
```
Project [Video Project] is already initialized.
INDEX.yaml location: <project_path>/INDEX.yaml
To re-initialize, run /aim-archive first or manually delete INDEX.yaml.
Operation aborted.
```
Stop.

**If it does not exist**: continue.

### Step 6: Create Project Structure

**Centralized mode**:
```
Run: mkdir -p <ROOT_PATH>/<SUBDIR_NAME>
```

**Distributed mode**:
```
Run: mkdir -p <ROOT_PATH>/.ai-memory
```

### Step 7: Generate INDEX.yaml

Read the template: `templates/INDEX.yaml.tpl`

Replace placeholders:
- `{{PROJECT_NAME}}` → PROJECT_NAME
- `{{MODE}}` → MODE (central / distributed)
- `{{ROOT_PATH}}` → absolute project path
- `{{CREATED_DATE}}` → today (YYYY-MM-DD)
- `{{UPDATED_DATE}}` → today
- `{{USER_ID}}` → identity.id
- `{{USER_NAME}}` → identity.name

Write to: `<project_path>/INDEX.yaml`

### Step 8: Inject CLAUDE.md Rules

**Determine CLAUDE.md path**:
- Centralized mode: `<ROOT_PATH>/CLAUDE.md`
- Distributed mode: `<ROOT_PATH>/CLAUDE.md`

**Check whether ai-memory rules are already injected**:
```
Read CLAUDE.md (if it exists)
Search for: <!-- ai-memory rules start
```

**If found**:
```
CLAUDE.md already contains ai-memory rules. Skipping injection.
```
Skip injection.

**If not found**: append the rules.

1. Read the template: `templates/claude-md-rules.md.tpl`
2. Replace placeholders:
   - `{{GITHUB_USER}}` → `shmxybfq`
   - `{{MODE}}` → MODE (central / distributed)
3. Handle conditional block `{{#CENTRAL}} ... {{/CENTRAL}}`:
   - **Centralized mode**: remove the `{{#CENTRAL}}` and `{{/CENTRAL}}` marker lines themselves (keep the content between them). Within that block, replace `{{PROJECT_MAPPING}}` with a list of all projects under this root directory:
     ```
     - <SUBDIR_NAME> → <PROJECT_NAME>
     ```
     If other projects already exist (scan sibling directories for INDEX.yaml), include them as well.
   - **Distributed mode**: delete the entire block from `{{#CENTRAL}}` to `{{/CENTRAL}}` (inclusive).
4. If CLAUDE.md does not exist, create it with the rules as its sole content.
5. If CLAUDE.md exists:
   - If it is a regular file: append the rules separated by `\n\n`.
   - If it is a **symbolic link**: resolve the link target and write to the target file (do not break the link). Inform the user: `CLAUDE.md is a symbolic link. Rules written to target [xxx]; link preserved.`

### Step 9: Git Initialization (Optional)

**Ask the user**:
```
Add this project to Git version control? (Y/n)
```

- Distributed mode defaults to Y (project code is typically already in git)
- Centralized mode defaults to n (personal document collection — may or may not use git)

**If Y**:
- Centralized mode: `cd <ROOT_PATH> && git init` (if not already in a git repo)
- Distributed mode: typically already in git; just add `.ai-memory/` to tracking

Commit:
```
git add <project files> <CLAUDE.md>
git commit -m "[aim-init] <PROJECT_NAME> - initialize project memory (<USER_NAME>)"
```

### Step 10: Output Summary

```
ai-memory initialization complete

Project info
  Project name: Video Project
  Mode: centralized
  Location: /Users/example/Desktop/persistent-document/bauto-video

User identity
  John Doe (u-a3b2f1c9)

Files created
  - /Users/example/Desktop/persistent-document/bauto-video/INDEX.yaml
  - /Users/example/Desktop/persistent-document/CLAUDE.md (rules appended)

Next steps
  1. /aim-add to add your first document
  2. /aim-status to view project status
  3. After collecting 3-5 documents, use /aim-compress to archive them

Tip
  At the start of each new session, Claude will automatically read INDEX.yaml
  and compressed documents — no need to re-explore the project.
```

## Edge Cases

### Case A: Identity file exists but is corrupted
- Attempt to parse the JSON.
- If parsing fails: notify the user and request permission to overwrite.
- Back up the old file as `identity.json.bak.<timestamp>`.

### Case B: Root directory path requires sudo (unlikely under macOS home directory)
- Skip and report error: `Cannot create directory [xxx]. Check permissions.`

### Case C: Project subdirectory name conflicts with an existing directory (not created by ai-memory)
- Check whether `<path>/INDEX.yaml` exists (already handled in Step 5).
- If the directory exists but has no INDEX.yaml: ask `Directory exists but is not an ai-memory project. Initialize here? (Y/n)`

### Case D: CLAUDE.md is read-only
- Detect on write attempt.
- Report error: `Cannot write to CLAUDE.md. Check file permissions.`

### Case E: User cancels mid-way (selects "cancel" or exits)
- Clean up any partially created files.
- Restore CLAUDE.md if it was partially modified.

## Soft Sandbox Behavior

/aim-init creates the project structure and injects CLAUDE.md rules. It does not create or modify user documents, so sandbox rules do not apply at this stage. The identity setup (Step 1) is global and not project-scoped.

## Output Style

- User-facing messages: plain English
- Code and file contents: English
- Use emojis in output for readability
- Display full file paths (clickable in terminal)

## References

- Template: `templates/INDEX.yaml.tpl`
- Template: `templates/claude-md-rules.md.tpl`
- Concept doc: `reference/central-vs-distributed.md`
