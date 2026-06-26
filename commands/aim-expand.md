---
name: aim-expand
description: Reverse-search snapshots to retrieve original details from a compressed topic. Reads archived documents that were folded into a compressed file. Read-only retrieval.
---

# /aim-expand — Retrieve Archived Details

## Purpose

After `/aim-compress`, source documents are archived into `snapshots/`. The compressed document preserves an integrated view, but details are lost. `/aim-expand` lets you pull back the original details when you need them.

Typical usage:
- The compressed document says "We considered approach A and B, and chose B"
- You want to know *why* A was rejected
- `/aim-expand <compressed_doc_id> topic=approach A comparison` -> retrieves the original discussion from snapshots

**Read-only.** Never modifies snapshots or compressed documents.

## Usage

```
/aim-expand <doc_id|filename> [--topic <keyword>] [--date <YYYY-MM-DD>]
```

- `doc_id` or filename: which compressed document to expand (or which snapshot to read).
- `--topic`: keyword to search within snapshots (e.g., `auth`, `routing`).
- `--date`: restrict to a specific snapshot date.

If no compressed document exists yet, `/aim-expand` lists available snapshots.

## Prerequisites

Default (see SKILL.md §G3). Additional:
- At least one snapshot exists, or a compressed document with an archive section

## Workflow

### Step 1: Resolve Current Project

Follow SKILL.md §G1. Store as `INDEX`.

### Step 2: Identify the Target

If a `<doc_id>` argument is provided:
- If it matches the current compressed document: target = compressed document + all snapshots that flowed into it.
- If it matches a snapshot file: target = that single snapshot.

If no argument is provided:
- List all snapshots with dates and brief content summaries.
- Ask the user which one to expand.

### Step 3: Identify the Snapshot Pool

For a compressed document target:
1. Read `INDEX.yaml`'s `compressed[0].sources` (if recorded) — an explicit list of source doc_ids.
2. If not recorded (earlier compression runs), fall back: scan all `snapshots/*/`, filter by date proximity to the compressed document's `created` date.

For a single snapshot target: just that one file.

### Step 4: Filter by Topic (if --topic provided)

For each snapshot file in the pool:
1. Read the content.
2. Search for the topic keyword (case-insensitive).
3. Score relevance (match count, position within the document).
4. Sort by relevance.

If `--topic` is not provided: include all snapshots in the pool.

### Step 5: Extract Relevant Sections

For each relevant snapshot:
- Extract paragraphs/sections containing the topic.
- Preserve the original formatting (HTML).
- Tag the source: `<snapshot_date>/<file>.html`, original title, original author.

### Step 6: Also Check the Compressed Archive Section

The compressed document itself has an archive section (deprecated content). Search there as well — sometimes the details you need are there rather than in the snapshots.

### Step 7: Output

Format as a readable view:

```
🔍 Expand: Approach A comparison

📌 Sources found (3 total)

━━━ 1. Authentication Module Design (2026-06-21) ━━━
Author: Zhu Taofeng (u-a3b2f1c9)
Original file: snapshots/2026-06-21/2026-06-21-auth-module-design.html

[Relevant section]
We considered three authentication approaches:
- Approach A: Session + Cookie (traditional, but mobile-unfriendly)
- Approach B: JWT + Refresh (stateless, good for multi-platform) ← Final choice
- Approach C: Full OAuth 2.0 (over-engineered, unnecessary for internal systems)

[Decision record]
Reason for rejecting A: mobile cookie handling is complex, and compatibility with RN WebView is poor.

━━━ 2. Early API Design (2026-06-15) ━━━
Author: Zhu Taofeng (u-a3b2f1c9)
Original file: snapshots/2026-06-21/2026-06-15-early-api.html

[Relevant section]
... (other relevant content)

━━━ 3. [Archive Section] Legacy Authentication Design (2026-05-20) ━━━
Source: Compressed document archive section
Status: deprecated (superseded by 2026-06-21)

[Relevant section]
... (archived legacy approach)

💡 Tips
  - This is original content and may differ from the compressed document's wording
  - When citing, use the original doc_id to tag the source
```

### Step 8: Optional Follow-up

Offer next-step options at the end:

```
Next steps
  - /aim-expand <doc_id> --topic <other keyword>     Search for another topic
  - /aim-status                                       Return to project status
```

## Edge Cases

### Case A: No snapshots exist (project has never been compressed)

```
No snapshots yet. Archives are only created after running /aim-compress.
```

### Case B: Topic not found in any snapshot

```
No content related to "xxx" found in snapshots.

Suggestions:
  - Try broader keywords
  - List all snapshots: /aim-expand (no arguments)
```

### Case C: Snapshot file referenced in INDEX is missing from disk

- Skip that file.
- Warn: `⚠️ Snapshot xxx has been deleted from disk and cannot be expanded`.

### Case D: Compressed document has no archive section (first compression, no deprecated content yet)

- Only search snapshots.
- Note: `The current compressed document has no archive section content`.

### Case E: Many matching snapshots (>10)

- Show the top 5 by relevance.
- Note: `Found N relevant snapshots, showing the top 5. Use --limit all to see all.`

### Case F: Cross-date expansion (user wants to compare different compressions)

- If `--date` is specified, restrict to that date.
- If the user wants a comparison mode: `/aim-expand <doc> --topic xxx --compare-dates 2026-05-01,2026-06-01` -> display the same topic side-by-side from both snapshots.

## Output Style

_Defaults from SKILL.md §G4 apply._ Additional:

- Use horizontal rules (━━━) to separate sources.
- Always display: author, original filename, snapshot date.
- Preserve original HTML formatting within extracted sections.
- Use clear `[Relevant section]` markers when quoting from archived documents.
- Include 💡 tips and follow-up suggestions at the end.

## Deviations from Global Rules

- Public command, no sandbox restrictions (G5 does not apply).
- Can read any snapshot regardless of owner (snapshots are project history, inherently public).

## References

- Companion commands: `/aim-compress`, `/aim-status`, `/aim-archive`
- Concept: `reference/document-lifecycle.md`
