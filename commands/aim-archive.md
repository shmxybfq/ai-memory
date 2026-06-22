---
name: aim-archive
description: Move a document from the active list to the snapshots directory. For documents that are no longer current but should be preserved. Reversible operation.
---

# /aim-archive — Archive a Document

## Purpose

Move an active document into the snapshots directory. The document will no longer appear in new sessions' "active reading set," but is preserved for historical reference and `/aim-expand` retrieval.

How it differs from `/aim-compress`:
- `/aim-compress`: Merges multiple documents into one compressed file, then snapshots the originals.
- `/aim-archive`: Snapshots a single document without compression (it will not contribute to any compressed file).

Use cases:
- A document is outdated but you don't want to lose it
- A document represents a deprecated approach and you want to soft-delete it
- You're preparing to compress but want to exclude certain documents from the merge

**Reversible**: `/aim-expand` can read archived documents; manually moving the file back + rebuilding the INDEX restores active status.

## Usage

```
/aim-archive <doc_id|filename> [--reason <text>]
```

- `doc_id` or filename: Target document.
- `--reason <text>`: Optional. Reason for archiving (recorded in INDEX).

## Prerequisites

- Project is initialized.
- Target document exists in the `active` list.
- User identity is established.

## Workflow

### Steps 1-4: Parse project, identity, document, sandbox check

Same as `/aim-append` steps 1-4.

For `/aim-archive`, cross-user confirmation applies (archiving another user's document affects project state).

### Step 5: Confirm intent

Always confirm before archiving:

```
About to archive document

Document: Authentication Module Design (aim-20260621-a3b2f1)
Author: Zhu Taofeng
Created: 2026-06-21
Version: 2

After archiving:
  - File will be moved to snapshots/2026-06-21/
  - Will no longer appear in /aim-status active list
  - Still retrievable via /aim-expand
  - Will NOT be included as a source in the next /aim-compress

Confirm archive? (Y/n)
```

### Step 6: Determine snapshot location

Snapshot path: `<root>/snapshots/YYYY-MM-DD/<filename>`

If a file with the same name already exists (same day, same name archived): append a `-N` suffix.

### Step 7: Move the file

```
mv <root>/<filename> → <root>/snapshots/YYYY-MM-DD/<filename>
```

Use `mv` (not copy) — the document leaves the active area.

### Step 8: Update document metadata

Read the moved file. Update its metadata header:

```
status=archived
archived_at=2026-06-21
archived_by=u-a3b2f1c9
archive_reason=<reason text or "manual">
```

Write back.

### Step 9: Update INDEX.yaml

1. Remove the entry from the `active` list.
2. Add to the `snapshots` list:

```yaml
- date: "2026-06-21"
  reason: "<reason or manual>"
  files:
    - "<filename>"
  archived_from: "<doc_id>"
  archived_by: "u-a3b2f1c9"
```

3. Update the top-level `updated` to today.

### Step 10: Git commit (optional)

```
git add snapshots/ INDEX.yaml
git rm <old active path>  # file has been moved away
git commit -m "[aim-archive] <PROJECT_NAME> - archived <filename> [cross-user:from <name>] (doc:<DOC_ID>)"
```

### Step 11: Output result

```
Document archived

Archive details
   Document: Authentication Module Design (aim-20260621-a3b2f1)
   Reason: Manual archive / <user-provided reason>
   Operator: Zhu Taofeng (u-a3b2f1c9)

File location
   Archived to: /Users/.../snapshots/2026-06-21/2026-06-21-auth-module-design.html
   (Removed from active area)

Project status
   Active: 5 docs (was 6)
   Compressed: 1 doc
   Snapshots: 3 directories

Next steps
   - /aim-status              View updated status
   - /aim-expand <doc_id>     Retrieve archived content if needed
   - Manual restore: mv file back to root + /aim-rebuild
```

## Edge Cases

### Case A: Archiving the last active document

- Allowed, but warn: `After archiving, the project will have 0 active documents. Continue? (Y/n)`.

### Case B: Document has dependents (other documents reference it)

- Scan other active documents for references to this doc_id or title.
- If references found: warn `The following documents reference [xxx]: [list]. After archiving, these references will become dead links. Continue? (Y/n)`.

### Case C: Document is already referenced in the compressed document's archive section

- It's already preserved there. Archiving the active copy is safe.
- Note: `This document also exists in the compressed document's archive section. This archive action applies to the active copy.`

### Case D: Today's snapshot directory already has many files

- Allowed. Just note: `Today's snapshot directory already has N files. Consider running /aim-compress to consolidate when appropriate.`

### Case E: Provided reason text is very long

- Truncate to 200 characters in INDEX.yaml. Write the full reason into the archived file's metadata.

## Output Style

- Use English throughout.
- Always show the "from → to" path change.
- Show before/after counts in project status.
- Emojis: ✅ 📋 📁 📊 📝 ⚠️

## Soft Sandbox Behavior

- Own documents: One confirmation, then free to archive.
- Others' documents: Cross-user confirmation required every time.
- Public/archived documents: Not applicable (already archived).

## References

- Companion commands: `/aim-expand` (reverse retrieval), `/aim-compress` (batch archive via merge)
- Concept: `reference/document-lifecycle.md`
