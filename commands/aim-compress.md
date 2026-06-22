---
name: aim-compress
description: Merge active documents into a single compressed HTML file using a dual-zone (active + archive) structure. MVP: single-round LLM merge with rule-based validation. Trigger when active docs reach 3+.
---

# /aim-compress — Compress Active Documents (MVP)

## Purpose

Consolidate multiple active documents into **one** compressed HTML file, organized into two zones:
- **Active zone**: currently valid knowledge — the default read target for new sessions.
- **Archive zone**: deprecated/superseded content, preserved for traceability but soft-deleted from active reads.

After compression, the original active documents are moved to `snapshots/YYYY-MM-DD/` (recoverable) and the `active` list in INDEX.yaml is cleared.

**This is the MVP version**: a single-round LLM merge with rule-based validation for hard information (version numbers, file paths, commands, config values). The full three-stage pipeline (analyze -> merge -> validate with retry) is deferred to v0.2.

When to use:
- Active documents have accumulated to 3+ (`/aim-status` will prompt)
- A major phase transition is imminent (e.g., architecture migration)
- Active list token count exceeds comfortable reading budget (~30k)

## Usage

```
/aim-compress [--dry-run] [--include <doc_id1,doc_id2,...>] [--exclude <doc_id1,...>]
```

- `--dry-run`: show what will be compressed and the proposed outline, but do not write.
- `--include`: compress only the listed doc_ids (default: all active).
- `--exclude`: compress all active, except the listed ones.

No arguments: compress all active documents.

## Prerequisites

- Project is initialized.
- At least 1 active document (warn if < 3, allow override).
- INDEX.yaml is consistent (suggest `/aim-verify` first if uncertain).
- User has write permission to the project root directory.

## Workflow

### Step 1: Resolve Current Project

Same as `/aim-add` Step 1.

### Step 2: Resolve User Identity

Read `~/.claude/ai-memory/identity.json`. Required — compression records the operator.

### Step 3: Select Source Documents

Default: all entries in the `active` list of `INDEX.yaml`.

Apply `--include` / `--exclude` filters as specified.

Validate:
- All selected doc_ids exist in INDEX.
- All corresponding files exist on disk.
- At least 1 document remains after filtering.

If fewer than 3 documents are selected: warn `Only N documents selected. Compression is typically recommended at 3+. Continue? (Y/n)`.

### Step 4: Read All Source Documents

For each selected document:

1. Read the full HTML content.
2. Extract the body (strip `<head>`, `<style>`).
3. Record metadata: title, owner, created, source, tags.
4. Append to a `SOURCE_DOCS` list in positional order.

### Step 5: Check for Existing Compressed Document

If `INDEX.yaml` already has a `compressed` entry:

1. Read the existing compressed file.
2. Record its current active zone and archive zone content.
3. Set `MERGE_MODE = incremental` (merge new documents into the existing compressed doc).
4. Inform the user: `Existing compressed document detected. New content will be merged in and old versions archived.`

Otherwise: `MERGE_MODE = fresh`.

### Step 6: Generate Compressed Content (LLM Round)

This is the core step. Use the LLM (that is, yourself) to perform the consolidation.

**LLM Input**:
- All source documents (full text).
- In incremental mode: the existing compressed document content.
- Project name, current date, operator identity.

**LLM Instructions** (the internal prompt you must follow):

```
You are a project memory compression assistant. Merge the following documents into a single HTML document.

Requirements:
1. Output must strictly follow the structure of templates/compressed-template.html.tpl.
2. Content is divided into an "Active Zone" (7 fixed chapters) and an "Archive Zone".

Fixed chapters (Active Zone):
  1. Project Overview
  2. Architecture Evolution
  3. Current Architecture
  4. Core Components
  5. Technology Choices
  6. Key Decisions
  7. Known Limitations and TODOs

3. Merge rules:
   - Merge content on the same topic; remove duplicates.
   - Conflicting content: the newer version supersedes the older; move the older to the archive zone (deprecated).
   - Tag each content block with its source at the end: [Source: Document Title @ Author].
   - Preserve ALL hard information: version numbers, file paths, commands, config values, API names — keep them verbatim, do not rewrite.

4. Incremental mode (if applicable):
   - The "Active Zone" of the existing compressed document serves as the baseline.
   - New document content is woven into the corresponding chapters.
   - Old paragraphs superseded by new content are moved to the "Archive Zone", tagged [deprecated: superseded by <new document> @ date].

5. Forbidden:
   - Fabricating information not present in the source documents.
   - Deleting any specific version number, path, command, or config value.
   - Reversing the semantic meaning of technical decisions (condensing the wording is fine, but do not flip conclusions).

6. Output a "Merge Log" table at the end of the document listing how each source document was processed (merged / archived / partially retained).

Source documents follow:
[Paste all source documents in full]

Existing compressed document (incremental mode only):
[Paste existing compressed document, omit if none]

Project metadata:
- Project name: {{PROJECT_NAME}}
- Operation date: {{TODAY}}
- Operator: {{USER_NAME}} ({{USER_ID}})
```

**Output**: a complete HTML document following the compressed template.

**Chapter-Level Writing Requirements** (the LLM must obey):

Each chapter has a distinct content focus. The LLM must write according to each chapter's purpose — do NOT use the same writing style for every chapter:

| Chapter | MUST contain | MUST NOT contain |
|---|---|---|
| 1. Project Overview | A one-sentence project positioning, core use cases, target users | Detailed technical implementation |
| 2. Architecture Evolution | Timeline (V1 -> V2), the trigger for each upgrade | V1 implementation details (those go in the archive zone) |
| 3. Current Architecture | Architecture diagram currently in use, module boundaries, data flow | Deprecated modules |
| 4. Core Components | Each core component's responsibility, interface, key configuration | Large blocks of implementation code (compression is not code copying) |
| 5. Technology Choices | Comparison table (what was chosen + what was rejected + why) | Vague "we compared options" with no concrete reasoning |
| 6. Key Decisions | Decision point + final choice + rationale + impact | Discussion process, trial-and-error records |
| 7. Known Limitations and TODOs | Clear limitations, known bugs, planned work | Already-resolved old bugs |

If a chapter has no supporting content from any source document, explicitly write "(No content yet — awaiting future accumulation)" — do NOT fabricate filler.

**The metadata header MUST include a `sources=` field** (critical for `/aim-rebuild`):

```html
<!-- aim:doc_id=aim-YYYYMMDD-xxxxxx title=Compressed-PROJECT tags=compressed created=YYYY-MM-DD created_by=u-xxx owner=__project__ status=active source=compress version=1 sources=aim-yyy1,aim-yyy2,aim-yyy3 -->
```

The `sources=` value is a comma-separated list of all merged source doc_ids. This allows `/aim-rebuild` to recover the source list from the metadata header alone, without parsing the body.

### Step 7: Rule-Based Validation

After the LLM generates the compressed document, validate that hard information has been preserved.

For each source document, extract via regex:
- Version number strings: `\d+\.\d+(\.\d+)?` (e.g., `1.2.3`, `0.1`)
- File paths: `[\w\-/.]+\.\w+` (e.g., `src/index.ts`)
- Commands: `` `[^`]+` `` (backtick-wrapped)
- Config keys: `[A-Z_][A-Z0-9_]{2,}=` (e.g., `DATABASE_URL=`)
- API names: `\b(GET|POST|PUT|DELETE)\b /[\w-/]+`

Check whether each extracted item appears in the compressed output.

**Case-sensitivity rules**:
- Code identifiers (`Stack.Navigator`, `HMGET`, `jwt.sign`): **case-sensitive** — these are load-bearing information and must match exactly.
- Common words that happen to be capitalized in prose (`Modal` vs `modal`, `Token` vs `token`): **case-insensitive match is sufficient** — do not append to the appendix solely because of case mismatch.
- When uncertain, default to case-sensitive (safer). The cost of an appendix entry is low; the cost of lost information is high.

**If items are missing**:
1. List the missing items.
2. Choose one:
   - Re-prompt the LLM with an explicit instruction to include these items (at most one retry).
   - Manually append a `<!-- preserved-hard-info -->` block at the end of the compressed document listing the missing items verbatim.
3. Record the validation result in the merge log.

**MVP note**: at most one retry. If items are still missing after retry, preserve them in the appendix block verbatim. Do not loop.

### Step 7.5: Compressed Output Self-Check

After completing rule validation (Step 7), Claude self-checks the entire compressed document:

- [ ] **All 7 chapters present**: chapters 1-7 each have content (or explicitly state "(No content yet)")?
- [ ] **Chapters match their purpose**: each chapter follows the "Chapter-Level Writing Requirements" table from Step 6?
- [ ] **Source tags complete**: every content block ends with a `[Source: Document Title @ Author]` tag?
- [ ] **Zero hard information loss**: Step 7 rule validation passed (or missing items are in the preserved-hard-info appendix)?
- [ ] **No duplicate content**: same-topic content has been merged, no repeated paragraphs?
- [ ] **Conflicts resolved**: multiple versions of the same fact — newest in active zone, oldest in archive zone (tagged `[deprecated]`)?
- [ ] **Archive zone is justified**: content was moved to archive only because it was superseded, not to pad the section?
- [ ] **Merge log complete**: every source document's disposition is recorded?
- [ ] **Total length is reasonable**: compressed output < 30k tokens (warn if exceeded)?

If any item fails, revise before proceeding to Step 8 (write file).

### Step 8: Determine Output File

Filename: `compressed-YYYYMMDD.html` (e.g., `compressed-20260621.html`).

If the file already exists (a second compression on the same day): append a `-N` suffix (`compressed-20260621-2.html`).

Full path:
- Centralized mode: `<root>/<subdir>/compressed-YYYYMMDD.html`
- Distributed mode: `<project>/.ai-memory/compressed-YYYYMMDD.html`

### Step 9: Write Compressed Document

Write the HTML to the output path.

Verify the write succeeded (read back, check size > 1KB).

### Step 10: Archive Source Documents

For each source document:

1. Create a snapshot directory: `<root>/snapshots/YYYY-MM-DD/` (mkdir -p).
2. **Move** (not copy) the source HTML from its active location to the snapshot directory.
3. Record in the `snapshots` list of `INDEX.yaml`:
   ```yaml
   - date: "2026-06-21"
     reason: "compressed"
     files:
       - "2026-06-21-auth.html"
       - "2026-06-20-routing.html"
     compressed_into: "compressed-20260621.html"
   ```

Never delete source files — always move them to snapshots.

### Step 11: Update INDEX.yaml

1. Clear the `active` list (all entries have been moved to snapshots).
2. Update the `compressed` list:
   ```yaml
   compressed:
     - doc_id: "aim-20260621-<random>"
       file: "compressed-20260621.html"
       title: "Compressed-Video Project"
       owner: "__project__"
       created: "2026-06-21"
       created_by: "u-a3b2f1c9"
       created_by_name: "Zhu Taofeng"
       version: 1
       tokens: 12500
       sources_count: 6
       contributors:
         - { user: "u-a3b2f1c9", name: "Zhu Taofeng", last: "2026-06-21" }
   ```
3. Update the top-level `updated` field to today.
4. Update the `snapshots` list per Step 10.

Incremental mode: do not clear; replace the existing `compressed[0]` with the newly merged version (increment the `version` field).

### Step 12: Git Commit (Optional)

If the project is in a git repository:

```
git add compressed-YYYYMMDD.html snapshots/YYYY-MM-DD/ INDEX.yaml
git rm <old active files>  # files were moved, explicitly remove from git index
git commit -m "[aim-compress] <PROJECT_NAME> - 2026-06-21 compress and archive (merged N docs)"
```

If not in git: skip and note `Not in Git. Compressed document has been generated but is not version-controlled.`

### Step 13: Output Results

```
Compression complete.

Compression Summary
   Merged: 6 docs -> 1 compressed document
   Before: 8,400 tokens
   After:  12,500 tokens (net +4,100, but structured into 7 chapters)
   Operator: Zhu Taofeng (u-a3b2f1c9)
   Mode: fresh / incremental merge

Generated Files
   Compressed doc: /Users/.../compressed-20260621.html
   Snapshot dir:   /Users/.../snapshots/2026-06-21/ (6 source docs)

Validation Results
   Hard info preserved: 24/24 items
   Source tags: 6/6 docs
   Duplicate content merged: 12 paragraphs

Project Status (After Compression)
   Active:    0 docs
   Compressed: 1 doc (12,500 tokens)
   Snapshots: 3 directories (20 archived docs total)

Next Steps
   - /aim-add       Continue recording on the new baseline
   - /aim-status    View full project status
   - /aim-expand    Recover details from snapshots (if needed)
```

## Edge Cases

### Case A: Only 1-2 Active Documents

- Warn but allow override.
- Output: `Only N documents. Compression has limited value. Continue anyway? (Y/n)`.

### Case B: Active Documents Contain Conflicting Versions of the Same Fact

- The LLM should keep the newer version and archive the older one with a `[deprecated]` tag.
- If dates are the same or unknown: keep both in the active zone with an explicit "two competing claims exist" annotation.

### Case C: A Source Document Is Very Large (Single Doc > 5000 Tokens)

- Warn before compression.
- Suggest: `Document X is large. Consider splitting it first with /aim-edit, then compress. Include it anyway? (Y/n)`.

### Case D: Compressed Output Exceeds Reasonable Limit (> 30k Tokens)

- Warn: `Compressed output is estimated at N tokens. This may impact reading efficiency in new sessions. Consider splitting into multiple projects or archiving some content first.`
- Allow override.

### Case E: Validation Fails (Hard Information Still Missing After Retry)

- Do not discard the compressed result.
- Append the missing items as a `<!-- preserved-hard-info -->` block at the end of the compressed document.
- Add a warning to the output: `N hard-info items could not be woven into the body text and have been preserved in the appendix.`

### Case F: User Runs /aim-compress on an Empty Active List

- Stop: `No active documents. Nothing to compress.`

### Case G: Today's Snapshot Directory Already Exists (Second Compression on the Same Day)

- Append to the existing snapshot directory (do not overwrite).
- Append a `-N` suffix to filenames to avoid conflicts.

### Case H: Interruption Mid-Compression (Power Loss / Crash)

- Worst case: compressed doc is written but INDEX is not updated, or source files are moved but INDEX is not updated.
- Recovery: `/aim-verify` will flag inconsistencies; `/aim-rebuild` will reconcile from the filesystem.

## Output Style

- User-facing information in English.
- Display token counts before and after compression.
- Always show the snapshot path so the user knows where originals went.
- Emoji: use sparingly for section headers.
- Dry-run mode: display the proposed outline (chapter titles + where each document lands), no writes.

## Soft Sandbox Behavior

- `/aim-compress` is **special**: it modifies the shared compressed document (`owner=__project__`).
- Single-user projects: no additional confirmation beyond the standard flow.
- Multi-user projects: if any source document's owner differs from the current user, prompt:
  ```
  This compression includes documents from other users:
    - Zhang San (u-b1c2d3e4): 2 docs
    - Li Si (u-c3d4e5f6): 1 doc
  Cross-user compression of shared documents. Confirm? (Y/n)
  ```
- After confirmation, no caching (per project rules).

## MVP Limitations (vs Full v0.2)

- No three-stage pipeline (analyze/merge/validate as independent LLM calls with structured intermediate outputs).
- No iterative refinement loop (only one retry for hard-info misses).
- No per-chapter quality scoring.
- Cannot automatically detect when content should be split across multiple compressions.

What the MVP does provide:
- Dual-zone output (active + archive).
- Source attribution tags.
- Rule-based hard information validation.
- Original file snapshot preservation.
- Incremental merge with existing compressed documents.

## References

- Template: `templates/compressed-template.html.tpl`
- Design concept: `reference/three-stage-pipeline.md` (full design, deferred)
- Verification concept: `reference/rule-diff-verification.md`
- Companion commands: `/aim-status`, `/aim-expand`, `/aim-rebuild`
