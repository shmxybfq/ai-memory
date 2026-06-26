---
name: aim-status
description: Show project memory status. Displays document counts, token estimates, git drift warnings, and compression advice. Read-only — never modifies anything.
---

# /aim-status — Show Project Status

## Purpose

Display a snapshot of the current project's memory state: document inventory, token usage, contributor activity, git drift, and health warnings. **Read-only** — never writes, never commits.

Typical use cases:
- Verifying setup after `/aim-init`
- Periodically monitoring memory growth
- Judging whether compression is needed before `/aim-compress`
- Diagnosing anomalies (missing documents, corrupted INDEX, sync issues)

## Usage

```
/aim-status
```

No arguments. Always operates on the current project (resolved from cwd).

## Prerequisites

Default (see SKILL.md §G3). Additional: (none)

## Workflow

### Step 1: Resolve the current project

Follow SKILL.md §G1. Store as `INDEX`. If parsing fails, display the error (see Edge Case A).

### Step 2: Resolve user identity

Follow SKILL.md §G2 with **deviation**: missing identity only warns (do not stop) — `User identity not initialized — cannot distinguish personal vs. others' documents.` Continue execution.

### Step 3: Inventory active documents

For each entry in the `active` list of INDEX.yaml:

1. Verify that `<root>/<file>` exists on disk.
2. Read the metadata header from the file (`<!-- aim:doc_id=... -->`).
3. Cross-check INDEX.yaml fields against file metadata:
   - `doc_id`, `title`, `owner`, `status`, `updated`, `version`
4. Estimate tokens (from file size: `bytes / 3.5` as a rough heuristic, refined by Chinese/English content ratio).
5. Bucket by dimension:
   - Owner (self vs. others)
   - Source type (conversation / pitfall / external / decision)
   - Tags
6. Record anomalies:
   - File missing on disk
   - INDEX has entry but file metadata does not match
   - File exists but INDEX has no entry (orphan)

### Step 4: Inventory compressed documents

For `compressed` in INDEX.yaml:

1. Verify the compressed file exists.
2. Extract `version`, `created_by`, `contributors` from metadata header.
3. Estimate tokens.
4. Detect any stale active documents that still reference a compressed source (rare, may occur if rebuild order is wrong).

### Step 5: Inventory snapshots

Scan date subdirectories under `<root>/snapshots/`:

1. List all `snapshots/YYYY-MM-DD/` directories.
2. For each directory, count the HTML files inside.
3. Cross-check against the `snapshots` list in INDEX.yaml.
4. Flag orphan snapshot directories (on disk but not recorded in INDEX).

### Step 6: Check git drift

Only execute when `<root>` (or distributed project root) is inside a git repo:

1. Run `git status --porcelain` — count modified/untracked files in the memory directory.
2. Run `git fetch --dry-run` (skip if offline) — detect whether local is behind `origin/<branch>`.
3. Run `git log origin/<branch>..HEAD --oneline` — count ahead commits.
4. Run `git log HEAD..origin/<branch> --oneline` — count behind commits.

No caching — always fetch so the report reflects current remote state.

### Step 7: Calculate health metrics

Calculate and format:

- **Compression urgency**:
  - Active < 3: `Good`
  - 3–4: `Consider compressing`
  - 5–7: `Compression recommended`
  - 8+: `⚠️ Bloat risk — compress immediately`
- **Token budget** (rough context-window estimate):
  - Target: keep active total below ~30,000 tokens for smooth reading
  - Warn when exceeding 50,000
- **Largest single document** (flag if over 5,000 tokens)
- **Stale documents**: any `active` document not updated in 30+ days (by `updated` field)
- **Cross-user todo**: non-owner users present in `contributors` (indicates collaboration)

### Step 8: Output the report

Format the report as shown in the "Output Style" section below. Group with emoji headings. Keep it concise — ideally fits on one screen.

If verbose mode is requested (`/aim-status --detail`), also print a per-document table.

## Edge Cases

### Case A: INDEX.yaml is corrupted or unparsable

- Display the line where parsing failed.
- Suggest: `INDEX.yaml parse failed. Run /aim-rebuild to fix.`
- Do not continue with inventory — numbers would be misleading.

### Case B: Project has zero active documents (freshly initialized)

- Show empty state:
  ```
  Active documents: 0
  No documents yet. Run /aim-add to add your first one.
  ```

### Case C: File exists on disk but not in INDEX (orphan)

- List under "Anomalies": `File xxx.html exists but is not recorded in INDEX.yaml`
- Suggest running `/aim-rebuild` to align.

### Case D: INDEX has entry but file is missing

- List under "Anomalies": `INDEX records xxx.html but file does not exist`
- Suggest restoring from git or removing the INDEX entry.

### Case E: Git repo exists but no remote is configured

- Skip drift check, note: `Git is enabled but has no remote — cannot check behind status.`

### Case F: Git fetch fails (offline / auth)

- Skip remote check, note: `Cannot reach remote (offline?). Showing local state only.`

### Case G: Distributed mode but cwd is outside any project

- Step 1 resolution logic should catch this.
- If reached unexpectedly: error `Current directory is not inside any ai-memory project.`

### Case H: Mixed permissions (some documents private, some shared)

- In the document list, show a `permission` badge next to each line.
- No special action; informational only.

## Output Style

### Default Output

```
📊 ai-memory Project Status

📋 Project
   Name: Video Project
   Mode: Centralized
   Path: /Users/zhutaofeng/Desktop/persistent-document/bauto-video
   Initialized: 2026-06-15 (6 days ago)

👤 Current User
   Zhu Taofeng (u-a3b2f1c9)

📑 Documents
   Active: 6 (8,400 tokens)
   Compressed: 1 (12,500 tokens, 1 merge)
   Snapshots: 2 directories (14 archived)

📈 Active Distribution
   By source:
     - Conversation: 3
     - Pitfall: 2
     - Decision: 1
   By author:
     - Zhu Taofeng: 5
     - Zhang San: 1 (collaboration)

⚠️ Health Notes
   💡 6 active documents — consider running /aim-compress
   ⚠️ "Auth module refactor" is 5,200 tokens — consider splitting
   📅 "Early API design" not updated in 30+ days

🔄 Git Status
   Branch: main
   Uncommitted: 2 files (INDEX.yaml, 2026-06-21-auth.html)
   vs. remote: up to date

📝 Next Steps
   - /aim-compress     Compress active documents
   - git add .         Commit unsaved changes
   - /aim-verify       Full consistency check
```

### Verbose Output (`--detail`)

Append a per-document table after the summary:

```
📑 Active Document Details
| doc_id            | Title             | Author     | tokens | Updated     |
|-------------------|-------------------|------------|--------|-------------|
| aim-20260621-a3b2 | Auth module design | Zhu Taofeng | 1,200  | 2026-06-21  |
| aim-20260620-b1c2 | Route optimization pitfall | Zhu Taofeng | 800 | 2026-06-20 |
| aim-20260618-c3d4 | Third-party login plan | Zhang San | 1,500 | 2026-06-20 |
| ...               |                   |            |        |             |
```

### Formatting Rules

- All labels in English.
- Numbers use thousands separators (`8,400`).
- Dates in `YYYY-MM-DD` format.
- Relative time in parentheses (`6 days ago`, `2 hours ago`).
- Paths over 80 characters wrap to a new line (continuation indented 3 spaces).
- Consistent emoji usage: 📊 📋 👤 📑 📈 ⚠️ 🔄 📝 💡 🚫
- No trailing summary paragraph — keep it scannable.

## Deviations from Global Rules

- G2 (User Identity): warn-only on missing identity, do not stop (continue execution, cannot distinguish own vs. others' documents).
- G5 (Soft Sandbox): public command, no sandbox restrictions. Displays all documents regardless of owner.
- Contributor names shown as plain text (no PII beyond what is already recorded in INDEX.yaml).

## References

- Companion commands: `/aim-add`, `/aim-compress`, `/aim-rebuild`, `/aim-verify`
- Concept: `reference/document-lifecycle.md`
- Token estimation: Chinese ~1 char/token, English ~4 chars/token, HTML overhead ~50%
