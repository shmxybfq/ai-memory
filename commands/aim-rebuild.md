---
name: aim-rebuild
description: Rebuild INDEX.yaml from the filesystem. Use when INDEX is corrupted, out of sync, or manually edited. Reads metadata from HTML files and rebuilds the index. Safe to run at any time.
---

# /aim-rebuild — Rebuild INDEX.yaml

## Purpose

Completely rebuild `INDEX.yaml` from the filesystem by reading metadata headers embedded in HTML files. **The filesystem is the source of truth — INDEX.yaml is merely a rebuildable cache.**

Typical use cases:
- INDEX.yaml is corrupted or unparsable
- INDEX.yaml was manually edited and may be inconsistent
- Files were added/removed outside of ai-memory commands (e.g., manual file operations)
- After `/aim-verify` reports INDEX-to-filesystem drift
- As a recovery step after a failed or interrupted operation

**Safe to run at any time.** Always backs up the old INDEX.yaml before writing.

## Usage

```
/aim-rebuild [--dry-run]
```

- `--dry-run`: show what would change, but do not write. Recommended for first use.
- No arguments: rebuild and write.

## Prerequisites

- Project is initialized (INDEX.yaml has existed before; even if corrupted, the project directory structure must be intact).
- HTML files must have valid `<!-- aim:... -->` metadata headers.

## Workflow

### Step 1: Resolve the current project

Same as `/aim-status` Step 1. If possible, read the existing INDEX.yaml (to preserve project name, mode, root path).

### Step 2: Back up existing INDEX.yaml

If `INDEX.yaml` exists:

```
Copy INDEX.yaml → INDEX.yaml.bak.<YYYYMMDD-HHMMSS>
```

Keep the most recent 3 backups; older ones are rotated out. Do not delete backups without user permission.

### Step 3: Scan the filesystem

Walk the project memory directory:

```
<root>/                          ← <project>/.ai-memory/ in distributed mode
├── INDEX.yaml                   ← (will be overwritten)
├── *.html                       ← Active documents
├── compressed-*.html             ← Compressed document (single file)
├── snapshots/
│   ├── YYYY-MM-DD/
│   │   └── *.html               ← Archived snapshots
│   └── ...
└── ...
```

For each HTML file found:

1. Read the first 2KB (header region).
2. Extract metadata from the opening `<!-- aim:... -->` comment.
3. Parse key=value pairs: `doc_id`, `title`, `tags`, `created`, `created_by`, `owner`, `status`, `source`, `version`.
4. If no metadata header: mark as unmanaged file (skip from active list, report as orphan).
5. Estimate tokens from file size.
6. Read `last_modified_by` and `updated` from git blame if available; otherwise fall back to file mtime.

### Step 4: Classify files

Bucket each parsed file:

| Condition | Bucket |
|---|---|
| `owner=__project__` and filename starts with `compressed-` | `compressed` |
| `status=active` and in root or active directory | `active` |
| `status=archived` or in `snapshots/YYYY-MM-DD/` | `snapshots[YYYY-MM-DD]` |
| `status=deprecated` | Include in `compressed` archive area (verify against compressed doc) |
| No metadata header | Orphan (report, do not index) |

### Step 5: Rebuild INDEX.yaml

Construct the new structure:

```yaml
project: "<from old INDEX or root directory basename>"
mode: "<from old INDEX or detected: central if root in known roots list, otherwise distributed>"
root: "<absolute path>"
created: "<from old INDEX or earliest document created date>"
updated: "<today>"
version: 1

initialized_by:
  id: "<from old INDEX, or first document owner>"
  name: "<from old INDEX, or unknown>"

compressed: [<list from compressed bucket>]

active: [<list from active bucket, sorted by created descending>]

snapshots: [<list from snapshots bucket, each with {date, count, files}>]
```

For each `compressed` entry, derive fields:

```yaml
- doc_id: "<from metadata>"
  file: "<basename>"
  title: "<from metadata>"
  owner: "__project__"
  created: "<from metadata>"
  created_by: "<from metadata>"
  created_by_name: "<resolved from identity.json>"
  version: <from metadata, default 1>
  tokens: <estimated>
  sources_count: <count of source list>
  sources: [<split metadata 'sources' field by comma, e.g. "aim-xxx,aim-yyy" → ["aim-xxx", "aim-yyy"]>]
  contributors:
    - { user: "<created_by>", name: "<resolved>", last: "<created>" }
```

**If the compressed document metadata header lacks a `sources=` field** (old format from before this field was added): keep `sources: []` and note in output: `Compressed document [xxx] metadata missing sources field — cannot recover source document list.`

For each `active` entry, derive fields:

```yaml
- doc_id: "<from metadata>"
  title: "<from metadata>"
  file: "<basename>"
  owner: "<from metadata>"
  owner_name: "<resolved from identity.json or git config; fall back to id>"
  created: "<from metadata>"
  created_by: "<from metadata>"
  updated: "<from file mtime or git blame>"
  last_modified_by: "<from git blame latest committer, or owner>"
  version: <from metadata, default 1>
  status: "<from metadata, default active>"
  source: "<from metadata, default unknown>"
  tags: [<from metadata>]
  permission: private
  tokens: <estimated>
  contributors:
    - { user: "<owner>", name: "<resolved>", last: "<updated>" }
```

### Step 6: Dry-run diff (if --dry-run)

Show the user what would change:

```
📋 Rebuild Preview (--dry-run)

Current INDEX.yaml:
  Active: 5
  Compressed: 1
  Snapshots: 2

Rebuilt INDEX.yaml:
  Active: 6 (+1)
  Compressed: 1 (=)
  Snapshots: 2 (=)

Change details:
  + Added to active:
    - aim-20260621-xxx (new-document.html)
  - Removed from active:
    - aim-20260610-yyy (file does not exist)
  ⚠️ Field updates:
    - aim-20260615-zzz: title changed from "Old Title" to "New Title"

Proceed with rebuild? (Y/n)
```

Wait for confirmation. If the user declines, exit without writing.

### Step 7: Write INDEX.yaml

If not dry-run, or user confirmed:

1. Write new INDEX.yaml atomically (write to `INDEX.yaml.tmp` first, then `mv`).
2. Read back and parse to validate.
3. If parse fails: restore from backup and abort with error.

### Step 8: Output results

```
✅ INDEX.yaml rebuilt

📋 Rebuild Results
   Active: 6 (8,400 tokens)
   Compressed: 1 (12,500 tokens)
   Snapshots: 2 directories (14 archived)

📁 File Locations
   /Users/.../INDEX.yaml
   Backup: /Users/.../INDEX.yaml.bak.20260621-153022

⚠️ Notes
   - 1 orphan file not indexed: old-notes.html
   - 1 document missing file: aim-20260610-yyy (removed from INDEX)

📝 Next Steps
   - /aim-status    View full status
   - /aim-verify    Run deep consistency check
```

## Edge Cases

### Case A: Project has no HTML files at all (freshly initialized, INDEX corrupted)

- Rebuild produces an empty INDEX with only project metadata.
- Warn: `No documents found in project directory — rebuilt INDEX is empty.`

### Case B: HTML file metadata header is corrupted

- Attempt to parse, extract whatever keys are present.
- Fill missing fields with sensible defaults (`status=active`, `version=1`, etc.).
- Flag in output: `Document xxx.html has incomplete metadata — filled with defaults.`

### Case C: Multiple files share the same doc_id

- Should not happen (doc_id includes random suffix), but handle defensively.
- Keep the first one, warn about the duplicate.
- Suggest the user investigate manually.

### Case D: Compressed document references a missing source document

- If doc_ids referenced in the compressed document's archive area no longer exist on disk: this is expected (they have been archived).
- No action needed; the compressed document itself preserves the content.

### Case E: Read-only filesystem

- Detected during backup or write.
- Error: `Cannot write INDEX.yaml — check directory permissions.`

### Case F: identity.json is missing

- Cannot resolve owner_name from id.
- Fall back to showing the raw id (`u-a3b2f1c9`).
- Warn: `Cannot resolve usernames. Run /aim-identity to fix.`

## Output Style

- User-facing text in English.
- Show full file paths.
- Consistent emoji usage: ✅ 📋 📁 ⚠️ 📝 🔄
- Align columns in dry-run diff for readability.
- Always show the backup path so the user can manually roll back if needed.

## Soft Sandbox Behavior

- `/aim-rebuild` is a **public command** — no sandbox restrictions.
- Does not modify HTML files, only INDEX.yaml.
- Any user can safely run it on a project (this is cache rebuild, not content change).

## References

- Companion commands: `/aim-verify`, `/aim-status`
- Concepts: `reference/document-lifecycle.md`, `reference/rule-diff-verification.md`
