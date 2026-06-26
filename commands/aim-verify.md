---
name: aim-verify
description: Check INDEX.yaml consistency against the filesystem. Reports orphan files, missing files, metadata drift, and broken references. Read-only diagnostic tool.
---

# /aim-verify — Consistency Check

## Purpose

Audit the consistency between `INDEX.yaml` and the filesystem. Detects:
- Orphan files (on disk but not in INDEX)
- Missing files (in INDEX but not on disk)
- Metadata drift (INDEX fields do not match file headers)
- Broken references (snapshots pointing to empty locations, compressed docs missing sources)
- Token calculation discrepancies (INDEX tokens do not match actual estimates)

**Read-only.** Never modifies anything. Pair with `/aim-rebuild` to fix issues found here.

Typical use cases:
- Confirming `/aim-rebuild` produced correct results
- Periodic health checks
- When `/aim-status` shows anomalies
- Ensuring a clean state before compression

## Usage

```
/aim-verify [--fix]
```

- No arguments: report only.
- `--fix`: prompt to apply safe auto-fixes (update stale INDEX fields, remove broken entries). Unsafe fixes still require manual intervention.

## Prerequisites

Default (see SKILL.md §G3). Additional: (none)

## Workflow

### Step 1: Resolve the current project

Follow SKILL.md §G1. Store as `INDEX`.

### Step 2: Parse INDEX.yaml

If parsing fails: stop and prompt `INDEX.yaml parse failed. Run /aim-rebuild first to fix.`

### Step 3: Verify each active entry

For each entry in `INDEX.yaml` `active`:

1. **File existence**: does `<root>/<file>` exist?
   - Missing → record a `MISSING_FILE` error.
2. **Metadata match**: read the HTML header, compare against INDEX fields:
   - `doc_id` must match
   - `title` should match (warn on mismatch)
   - `owner` must match
   - `status` must be `active`
   - `version` should match
3. **Token accuracy**: re-estimate tokens from file size, compare against INDEX `tokens` field.
   - Warn if deviation > 20% (INDEX is stale).
4. **Contributor consistency**: every name in `contributors` should be resolvable via identity.json or git config.
5. **Date sanity**: `created <= updated`, and both are reasonable (not in the future, not before project initialization).

### Step 4: Verify compressed entries

For `compressed` in INDEX.yaml:

1. Does `<root>/<compressed-file>` exist?
2. Does the metadata header have `owner=__project__`?
3. Do the doc_ids referenced in the archive area still exist as active files? (May indicate an incomplete compression.)
4. Sanity check of token estimate vs. actual file size.

### Step 5: Verify snapshots

For each entry in `INDEX.yaml` `snapshots`:

1. Does `<root>/snapshots/<date>/` directory exist?
2. Does file count match INDEX?
3. Is each file's metadata valid inside?

Also scan the filesystem for directories under `<root>/snapshots/*/` that are not recorded in INDEX (orphans).

### Step 6: Scan for orphan files

Walk `<root>/*.html` (distributed: `<project>/.ai-memory/*.html`):

- Any HTML file with a valid `<!-- aim:... -->` header that is not in any INDEX list → orphan.
- Any HTML file without a metadata header → unmanaged (suggest user delete or add metadata).

### Step 7: Cross-reference checks

- Every `doc_id` in INDEX should be unique.
- Every `file` path should be unique.
- `compressed` list should have at most one entry (single-file compression model).
- `last_modified_by` should appear in the `contributors` list.

### Step 8: Classify findings

Group by severity:

| Severity | Meaning | Example |
|---|---|---|
| 🔴 ERROR | Data loss risk, must fix | Missing file, parse failure, duplicate doc_id |
| 🟠 WARN | Drift, should fix | Stale tokens, title mismatch, old backup files |
| 🟡 INFO | Informational | Orphan file (may be user-managed), unmanaged HTML |
| 🟢 OK | All checks passed | (Only shown when no other issues exist) |

### Step 9: Apply auto-fixes (if --fix)

For each WARN/INFO that has a safe automated fix:

1. **Stale tokens**: recalculate and update INDEX.
2. **Title mismatch**: use the file's title (filesystem is source of truth).
3. **`last_modified_by` missing from contributors**: add it.

Skip auto-fixes for:
- 🔴 ERROR items (require user judgment)
- Orphan files (may be intentional)
- Any operation that would delete content

Before writing, show proposed changes and ask for confirmation:

```
📋 Ready to auto-fix 3 items

1. aim-20260620-xxx: tokens 800 → 920 (recalculated)
2. aim-20260615-yyy: title "Old Title" → "New Title" (read from file header)
3. aim-20260610-zzz: add contributor u-b1c2d3e4

Proceed? (Y/n)
```

Back up INDEX.yaml before writing (same as `/aim-rebuild`).

### Step 10: Output the report

```
🔍 Consistency Check Report

📊 Summary
   Checks: 24
   Passed: 21
   Warnings: 2
   Errors: 1

🔴 Errors (1)
   1. [MISSING_FILE] aim-20260610-yyy
      INDEX records file `2026-06-10-old.html` but it does not exist
      Fix: Restore from git, or run /aim-rebuild to remove this entry

🟠 Warnings (2)
   1. [TOKEN_STALE] aim-20260620-xxx
      INDEX records 800 tokens, actual ~920 tokens
      Fix: Run /aim-verify --fix to auto-update
   2. [TITLE_DRIFT] aim-20260615-yyy
      INDEX: "Old Title", file header: "New Title"
      Fix: Run /aim-verify --fix to use file as source of truth

🟡 Info (1)
   1. [ORPHAN_FILE] old-notes.html
      File exists but is not in INDEX — may have been added manually
      Fix: Run /aim-add to register if you want it managed

🟢 Passed Checks (21 items)
   ✅ All doc_ids unique
   ✅ All file paths unique
   ✅ Compressed document intact
   ✅ Snapshot directories consistent
   ...

📝 Next Steps
   - /aim-verify --fix    Auto-fix fixable items
   - /aim-rebuild         Fully rebuild INDEX
   - Fix errors manually, then re-run /aim-verify
```

## Edge Cases

### Case A: INDEX.yaml itself fails to parse

- Stop immediately.
- Suggest: `INDEX.yaml parse failed. Run /aim-rebuild.`
- Do not attempt partial verification.

### Case B: Project has zero active documents and zero compressed documents

- Valid state (freshly initialized).
- Report: `🟢 Project is empty — nothing to check.`

### Case C: identity.json is missing

- Cannot resolve contributor names.
- Warn but continue: `Cannot resolve usernames — showing IDs instead.`

### Case D: Git history is available

- Optionally cross-check `last_modified_by` against actual git committers.
- If mismatch: 🟠 WARN (INDEX may be stale).

### Case E: Unsafe change encountered during --fix

- Abort the entire fix batch (do not apply partial fixes).
- If any writes occurred, restore from backup.
- Report what was attempted and why it was aborted.

### Case F: A check requires network (e.g., identity sync)

- Skip that check, note in report: `Skipped X check (requires network).`

## Output Style

_Defaults from SKILL.md §G4 apply._ Additional:

- Severity emoji: 🔴 🟠 🟡 🟢
- Issue codes in `[UPPER_SNAKE_CASE]` for easy grep.
- Align issue numbers with descriptions.
- Summary counts always shown first.
- Truncate long file lists with `... and N more`, and offer a `--detail` option.

## Deviations from Global Rules

- Public command, no sandbox restrictions (G5 does not apply).
- `--fix` mode only touches INDEX.yaml cache (not content), considered safe for any user.

## References

- Companion commands: `/aim-rebuild`, `/aim-status`
- Concept: `reference/rule-diff-verification.md`
