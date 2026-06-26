---
name: aim-add
description: Add a new document to project memory. Always creates a new file (never modifies existing documents). Used to record knowledge, decisions, debugging notes, or summaries.
---

# /aim-add -- Add New Document

## Purpose

Create a new HTML document in the project memory directory with proper metadata and an updated INDEX.yaml. **Always creates a new file** -- use `/aim-append` to extend an existing document, or `/aim-edit` to modify one.

## Usage

```
/aim-add [natural language content or description]
```

- If arguments are provided, use them directly as the content.
- If no arguments are given, prompt the user to paste content or describe what to record.

## Prerequisites

Default (see SKILL.md §G3). Additional: (none)

## Workflow

### Step 1: Resolve Current Project

Follow SKILL.md §G1. Store result as `INDEX`.

### Step 2: Resolve User Identity

Follow SKILL.md §G2. Store result as `USER`.

### Step 3: Collect Document Content

**If the command was invoked with arguments**: use them directly as `RAW_CONTENT`.

**If no arguments were provided**, prompt the user:
```
Enter the content to record (can be a natural language description, technical decision, debugging notes, etc.):
[Wait for user input, may span multiple lines]
```

Store as `RAW_CONTENT`.

### Step 4: Determine Document Metadata

#### 4.1 Title

Inspect RAW_CONTENT. If it opens with a clear topic, generate a title suggestion.

Ask the user:
```
Suggested title: [generated title based on content]
Confirm or modify (press Enter to confirm):
```

Store as `TITLE`.

#### 4.2 Source

Ask the user (with default):
```
Document source:
1. Conversation (dialogue capture, decision record)
2. Pitfall (bug, troubleshooting)
3. External (reference material, link collection)
4. Decision (tech selection, solution comparison)
Choose (1-4, default 1):
```

Store as `SOURCE` (conversation/pitfall/external/decision).

#### 4.3 Tags

Ask the user (optional):
```
Tags (comma-separated, optional, e.g. auth,security,api):
```

If empty, use `[]`. Otherwise parse as a list. Store as `TAGS`.

#### 4.4 Filename

Generate from TITLE:
- Replace spaces with `-`
- Remove special characters except `-`, `_`, `.`
- Prepend with date prefix `YYYY-MM-DD-`
- Example: `2026-06-21-auth-module-design.html`

If the filename conflicts with an existing file in the project directory:
```
File [xxx.html] already exists. Options:
1. Auto-append suffix (auth-module-design-2.html)
2. Enter a different filename
Choose (1/2):
```

Store as `FILENAME`.

#### 4.5 Document ID

Generate: `aim-` + `YYYYMMDD` + `-` + 6-character random alphanumeric string.
Example: `aim-20260621-a3b2f1`.

Store as `DOC_ID`.

### Step 5: Generate HTML Content

#### 5.1 Role Definition

**You are not a "conversation transcript clerk." You are a project memory distillation assistant.**

The reader is a future Claude session, 6 months from now, that needs to quickly understand the project without re-exploring it. That session will not read your raw conversation -- it will only read the document you produce.

**Core objective**: extract **knowledge that will be useful in the future** from RAW_CONTENT, not merely record what happened.

> **Failure mode warning**: The 4 most common failures when an LLM distills documentation -- writing a chronological log, fabricating authoritative numbers, retaining trial-and-error processes, copying information that is already inferrable from code. Rules 5.2-5.6 below are designed to prevent these failures.

#### 5.2 Must-Write (ALWAYS include)

1. **Decision records**: what was chosen + why alternatives were rejected
2. **Facts not easily inferred from code**: architectural principles, domain rules, business constraints, design intent
3. **Root causes of pitfalls** (not symptoms): why the bug existed and how to prevent recurrence
4. **Long-term constraints**: rules that must be followed, limits that must not be violated
5. **Key configurations/commands**: actual version numbers, file paths, commands, configuration values (preserve verbatim)
6. **Workflows**: standard steps for a task (command sequences, decision branches)

#### 5.3 Must-Not-Write (NEVER include)

1. **Chronological logs**: "We discussed A, then we discussed B" -- only keep B's conclusion
2. **Trial-and-error processes**: "Tried X and it failed, tried Y and it failed" -- only keep the final solution + reasons X/Y were rejected
3. **Transient states**: "Currently X, might change later" -- wait until it's settled before writing
4. **Inferrable information**: anything directly readable from code structure, function signatures, or config files
5. **Chatter/pleasantries**: "OK", "Got it", "I agree"
6. **Duplicate information**: content already present in compressed documents or other active project docs (reference it, do not copy)
7. **Outdated information**: old versions superseded by new decisions (if retention is necessary, tag `[deprecated]`)
8. **Fabricated content**: do not write what was not said. If something is uncertain, tag `[unconfirmed: specific detail]`. **Never invent numbers or facts to appear authoritative.**

#### 5.4 Writing Style

**Paragraph structure**:
- Lead with the conclusion: the first sentence of every paragraph gives the takeaway; supporting reasoning/context follows
- Limit each paragraph to 5 lines; split if longer

**Information density**:
- Target 800-2000 words per document (English equivalent). If exceeding 2000 words, prompt the user to split into multiple documents -- but do not forcibly block the write
- Do not pad with filler to hit a word count; do not omit critical information for brevity

**Temporal annotations**:
- Permanent decisions: no annotation
- Temporary decisions: prefix the paragraph with `[temporary - plan to resolve by YYYY-MM-DD via ABCD]`
- Unconfirmed: `[unconfirmed: specific detail]`
- Deprecated: `[deprecated - superseded by XXX as of YYYY-MM-DD]`

**Hard information preservation** (critical):
- Version numbers, file paths, commands, configuration values, API names -- **preserve verbatim** (do not translate, rephrase, or simplify)
- Example: `React Navigation v6.1.4` must not become `React Navigation v6`
- Once this information is lost, it is permanently unrecoverable

**Source attribution** (optional but recommended):
- After key assertions, append `[source: conversation N]` or `[source: explicitly stated by user]`
- Enables future readers to trace provenance

#### 5.5 Structure Templates (select by SOURCE type)

**SOURCE=decision**:
```
## Background
(Why this decision was needed)

## Options Compared
| Option | Pros | Cons |
|---|---|---|
| A | ... | ... |
| B | ... | ... |

## Final Choice
(What was selected)

## Rationale
(Why this option, and why others were rejected)

## Impact
(Constraints and consequences introduced by this decision)
```

**SOURCE=pitfall**:
```
## Symptom
(What it looks like, repro steps)

## Root Cause
(The real cause, not the surface observation)

## Fix
(How it was resolved, key commands/code)

## Prevention
(How to avoid this going forward)
```

**SOURCE=external**:
```
## Source
(Link, book title, author)

## Key Takeaways
(Distilled insights, not verbatim copy)

## Relevance to This Project
```

**SOURCE=conversation**:
```
## Topic
(What this discussion was about)

## Key Conclusions
(What was determined)

## Decisions and Rationale

## Action Items (if any)
```

#### 5.6 Counter-Examples (avoid these failures)

**Counter-example 1: Chronological log -> Lead with conclusion**

Bad:
```
The user first asked how to do authentication, I introduced JWT, then the user asked if cookies would work,
I compared the pros and cons, the user felt cookies were cumbersome on mobile, and finally we decided to use JWT
with a 15-minute expiry and a 7-day refresh token.
```

Good:
```
## Decision: Authentication uses JWT + Refresh Token dual-token scheme

- Access Token: 15min, held in client memory
- Refresh Token: 7d, stored server-side in Redis

Session-based approach was rejected because cookie handling on mobile is complex and cross-origin flows are problematic.
```

**Counter-example 2: Writing symptoms -> Writing root cause**

Bad:
```
There was a 200ms white flash on the page. After investigation, we fixed it.
```

Good:
```
## Symptom
List page to detail page transition shows a 200ms white flash.

## Root Cause
React Navigation v6.1.4 on RN 0.72 has high performance overhead for modal presentation.

## Fix
Switched to `presentation: 'card'`.

## Prevention
Do not set `presentation: 'modal'` globally. Only apply it to individual screens that require modal behavior.
```

**Counter-example 3: Fabrication -> Annotation**

Bad:
```
This approach delivers a 50% performance improvement.
```

Good:
```
This approach is expected to perform better (not yet benchmarked; load testing pending).
```

**Counter-example 4: Duplicating existing content -> Incremental reference**

Bad (assuming compressed doc already covers V1 architecture in detail):
```
V1 architecture consists of four stages: preprocessing, narration, TTS, and rendering. Preprocessing is responsible for...
```

Good:
```
This entry records the differences between V2 and V1:
- Added: text effects pipeline
- Removed: V1's dual-track encoding

See the compressed document for the complete V1 architecture.
```

#### 5.7 Self-Check Checklist (must pass before writing the file)

After completing the RAW_CONTENT -> HTML conversion, **Claude must verify all 7 items below**. If any item fails, revise before writing:

- [ ] **Lead with conclusions**: does every paragraph's first sentence state the takeaway, not the process?
- [ ] **No chronological logs**: have all "we first discussed... then..." narrative passages been removed?
- [ ] **Hard information intact**: are all version numbers, paths, commands, and config values preserved verbatim?
- [ ] **Temporal annotations applied**: do temporary/unconfirmed/deprecated items carry the appropriate tags?
- [ ] **No duplication**: does the document avoid repeating content already in compressed docs or other active docs?
- [ ] **No fabrication**: are there no invented numbers or facts? Are uncertain items tagged `[unconfirmed]`?
- [ ] **Reasonable length**: is the document within the 800-2000 word range (or has the user been prompted if it exceeds this)?

#### 5.8 Render HTML Template

After passing self-check, wrap the content in the template:

- Template file: `templates/doc-template.html.tpl`
- Section layout: title, metadata block, content sections, footer
- Convert markdown-style content (lists, code blocks, tables) to appropriate HTML
- The template includes built-in CSS; do not redefine styles

**Template placeholder substitutions**:
- `{{DOC_ID}}` -> DOC_ID
- `{{TITLE}}` -> TITLE
- `{{TAGS}}` -> TAGS joined as a string
- `{{CREATED}}` -> today's date (YYYY-MM-DD)
- `{{CREATED_BY}}` -> USER.id
- `{{OWNER}}` -> USER.id
- `{{OWNER_NAME}}` -> USER.name
- `{{SOURCE}}` -> SOURCE
- `{{CONTENT}}` -> structured HTML generated through steps 5.1-5.7

**Metadata header in HTML comment** (already in the template):
```html
<!-- aim:doc_id=aim-20260621-a3b2f1 title=Auth Module Design tags=auth,security created=2026-06-21 created_by=u-a3b2f1c9 owner=u-a3b2f1c9 status=active source=conversation -->
```

### Step 6: Write File

Determine the write path:
- Centralized mode: `<ROOT>/<SUBDIR>/<FILENAME>`
- Distributed mode: `<ROOT>/.ai-memory/<FILENAME>`

Write the HTML content to the file.

### Step 7: Update INDEX.yaml

Append to the `active` list:
```yaml
- doc_id: "aim-20260621-a3b2f1"
  title: "Auth Module Design"
  file: "2026-06-21-auth-module-design.html"
  owner: "u-a3b2f1c9"
  owner_name: "Zhu Taofeng"
  created: "2026-06-21"
  created_by: "u-a3b2f1c9"
  updated: "2026-06-21"
  last_modified_by: "u-a3b2f1c9"
  version: 1
  status: "active"
  source: "conversation"
  tags: [auth, security]
  permission: "private"
  tokens: <estimated>
  contributors:
    - { user: "u-a3b2f1c9", name: "Zhu Taofeng", last: "2026-06-21" }
```

Update the top-level `updated` field in INDEX.yaml to today's date.

### Step 8: Estimate Tokens

Estimate tokens for the new document (rough heuristic: Chinese ~1 char = 1 token, English ~4 chars = 1 token, HTML tags add ~50% overhead).

Write the estimated value into the active entry's `tokens` field.

### Step 9: Git Commit (Optional)

Check whether the project is inside a git repository.

**If in a git repo**:
- `git add <FILENAME> INDEX.yaml`
- `git commit -m "[aim-add] <PROJECT_NAME> - created <FILENAME> (doc:<DOC_ID>)"`

**If not in a git repo**: skip and notify the user `Not tracked by Git. Document saved but not version-controlled.`

### Step 10: Output Result

```
Document added successfully

Document info
   Title: Auth Module Design
   doc_id: aim-20260621-a3b2f1
   Tags: auth, security
   Source: conversation

File location
   /Users/zhutaofeng/Desktop/persistent-document/bauto-video/2026-06-21-auth-module-design.html

Project status
   Active documents: 6 (total ~8,400 tokens)
   Compressed documents: 1 (~12,500 tokens)
   Note: 6 active documents -- consider running /aim-compress to consolidate

Next steps
   - Add another: /aim-add
   - View status: /aim-status
   - Compress and archive: /aim-compress
```

**Compression suggestion thresholds**:
- 3+ active docs -> gentle nudge
- 5+ active docs -> strong recommendation
- 8+ active docs -> warning (bloat risk)

## Edge Cases

### Case A: Project Not Initialized
- Detected by missing INDEX.yaml
- Stop: `Project not initialized. Please run /aim-init first.`

### Case B: Identity Missing or Invalid
- Stop: `User identity not initialized. Please re-run /aim-init or /aim-identity.`

### Case C: Filename Conflict (same title used before)
- Detect before writing
- Ask the user: rename or cancel

### Case D: Empty Content
- If RAW_CONTENT is empty or whitespace: `Content is empty. Operation cancelled.`

### Case E: Content Too Large
- If the single document is estimated at >5000 tokens:
  - Prompt the user: `Content is long (~X tokens). Consider splitting into multiple documents. Continue? (Y/n)`

### Case F: Corrupted INDEX.yaml
- Attempt to parse the YAML
- If parsing fails: `INDEX.yaml is corrupted. Please run /aim-rebuild to fix and retry.`

## Output Style

_Defaults from SKILL.md §G4 apply._ Additional:

- Emoji: ✅ 📋 📁 📊 💡 ✏️ (checkmark, clipboard, folder, chart, lightbulb, pencil)
- Keep output concise but sufficiently informative

## Deviations from Global Rules

None.

## References

- Template: `templates/doc-template.html.tpl`
- Concepts: `reference/document-lifecycle.md`
- Related commands: `/aim-append`, `/aim-edit`
