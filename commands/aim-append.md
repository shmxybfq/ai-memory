---
name: aim-append
description: Append a new section to an existing document. Preserves all original content and adds a new section at the end. Triggers cross-user confirmation when the document owner differs from the current user.
---

# /aim-append — Append Content to an Existing Document

## Purpose

Appends a new section to the end of an existing document without altering any original content. Use cases include:

- Adding updates to a decision log
- Recording follow-up debugging notes
- Supplementing a research document with new findings

Distinct from `/aim-edit` (modifies existing content) and `/aim-add` (creates a new file).

## Usage

```
/aim-append <doc_id|filename> [content]
```

- `doc_id` or `filename`: The target document.
- `content`: Optional. The new section content. If omitted, the user is prompted to provide it.

## Prerequisites

- The project must be initialized.
- The target document must exist (listed in `INDEX.yaml` under `active`, and the file must be present on disk).
- The user identity must be established.

## Workflow

### Step 1: Resolve the Current Project

Same as `/aim-add` Step 1.

### Step 2: Resolve User Identity

Read `~/.claude/ai-memory/identity.json`. Required.

### Step 3: Resolve the Target Document

Match the `<doc_id|filename>` argument:

1. Try an exact `doc_id` match in `INDEX.yaml`'s `active` list.
2. Try matching by filename (basename).
3. Try a partial title match (if multiple matches, interactively confirm).

If not found in `active`: also check the archive area for compressed documents. Cannot append to archived documents — suggest `/aim-expand` first, or use `/aim-add` instead.

If not found anywhere: `Document [xxx] does not exist. Run /aim-list to see all documents.`

Save the matched entry as `DOC`.

### Step 4: Check Soft Sandbox (Cross-User)

Compare `DOC.owner` with the current user ID.

**Same user**: No confirmation needed. Proceed directly.

**Different user** (cross-sandbox):

```
Cross-user operation

Document [xxx] is owned by [Alice] (u-b1c2d3e4).
You [Bob] (u-a3b2f1c9) are not the owner.

Confirm appending content to another user's document?
This operation will be annotated with [cross-user:from Bob @ 2026-06-21].

Confirm? (Y/n)
```

Per project rules: no caching — every cross-user operation requires fresh confirmation.

**If declined**: Abort and display `Operation cancelled`.

### Step 5: Collect New Section Content

If the argument provided content: use it as `RAW_CONTENT`.
Otherwise, prompt:

```
Enter the content to append (e.g., supplementary notes, new findings, progress updates):
[wait for user input]
```

### Step 6: Determine Section Metadata

Ask the user (with a sensible default):

```
Section title (optional, default: "Update - YYYY-MM-DD"):
```

Save as `SECTION_TITLE`.

### Step 7: Generate the HTML Section

#### 7.1 Role Definition

**You are not "rewriting the document." You are "adding a supplementary chapter to an existing document."**

The reader is a future session 6 months from now, reading the full document (original sections + your appended section). Your section must:

- **Complement** the original sections (add new information), not **duplicate** them (repeat what the original already says).
- **Match the original's style** (the reader should feel they are reading one cohesive document, not a patchwork).

> **Failure mode warning**: The 4 most common LLM mistakes when appending — (1) repeating information already in the original, (2) giving the appended section the same title as an existing section, (3) using a different style than the original (e.g., original uses tables, append uses running prose), (4) appends with information density so low it adds no value.

#### 7.2 Must Include

1. **New information not present in the original**: new decisions, newly discovered pitfalls, new constraints, new configurations.
2. **Clear timestamp**: `<p class="meta">Appended by XXX @ YYYY-MM-DD</p>`.
3. **Cross-reference to original sections** (if applicable): "Building on the approach in Section 3, this update adds..."

#### 7.3 Must Not Include

1. **Repetition of original content**: if the original already states X, do not restate X in the appendix.
2. **Overwriting the original** (use `/aim-edit` instead of `/aim-append`).
3. **Running diary** (same as `/aim-add` 5.3).
4. **Trial-and-error process** (same as `/aim-add` 5.3).
5. **Chatter** (same as `/aim-add` 5.3).
6. **Fabrication** (same as `/aim-add` 5.3).
7. **Style clash with the original**: if the original uses tables, the appendix must use tables; if the original is formal, the appendix must not be colloquial.

#### 7.4 Writing Style

**Align with the original**:
- Scan the original document first to identify its style (tables? lists? code blocks? typical paragraph length?).
- The appended section must follow the same conventions.

**Information density**:
- A single append should be 300-1500 words (lower than `/aim-add`'s 800-2000, since this is incremental).
- If content exceeds 1500 words, prompt the user to use `/aim-add` to create a standalone document instead.

**Temporal annotations**:
- Same as `/aim-add` 5.4 (`[temp]` / `[unconfirmed]` / `[deprecated]`).

**Hard information preservation**:
- Same as `/aim-add` 5.4 (version numbers, file paths, commands preserved verbatim).

#### 7.5 Structure Templates (by Append Type)

**Type A: Decision Supplement** (original recorded a decision; a new decision follows):

```
## Update - YYYY-MM-DD (or specific section name)

### New Decision
[decision content]

### Relationship to Original Decision
[supplement / correction / replacement]
```

**Type B: Pitfall Report** (original is a design/plan; implementation reveals issues):

```
## Implementation Pitfalls - YYYY-MM-DD

### Symptom
### Root Cause
### Fix
### Prevention
```

**Type C: Progress Update** (original is a to-do/plan; items are now complete):

```
## Progress Update - YYYY-MM-DD

### Completed
[list]

### Adjusted To-Dos
[added / removed / priority changes]
```

**Type D: Configuration Change** (original recorded a config; values have changed):

```
## Configuration Change - YYYY-MM-DD

### Change
[old value -> new value]

### Reason
### Impact Scope
```

#### 7.6 Counter-Examples

**Counter-example 1: Repeating the original**

Bad (original already says "using JWT"):
```
We confirmed continuing with the JWT approach; using JWT is reasonable...
```

Good:
```
JWT implementation details are now settled: using the jose library (v5.0.0), replacing the previous jsonwebtoken dependency.
```

**Counter-example 2: Style mismatch**

Bad (original uses comparison tables; append uses running prose):
```
We tried approach A again, it didn't work, then we tried B...
```

Good (following the table convention):
```
| Approach | Test Result | Conclusion |
|---|---|---|
| A | Failed | Performance below threshold |
| B | Passed | Adopted |
```

**Counter-example 3: Overwriting the original (should use /aim-edit)**

Bad:
```
The original "Approach Selection" section was wrong, so I'm rewriting it correctly here in this appendix.
```

Good:
```
(If the original contains errors, advise the user to fix them with /aim-edit — do not overwrite in an append.)
This appendix only supplements with new content; it does not rewrite existing sections.
```

**Counter-example 4: Append content is too long**

Bad (single append of 5000 characters):
```
[an oversized section containing an entire new module design]
```

Good:
```
(This content is too long for an append.)
Suggestion: this content is substantial enough for a standalone document. Consider using /aim-add instead.
```

#### 7.7 Self-Check Checklist (must pass before writing)

After generating the HTML section, Claude must verify:

- [ ] **No repetition**: the appended content does not duplicate anything already in the original.
- [ ] **Style consistent**: matches the original document's conventions (tables / lists / paragraph format).
- [ ] **No title collision**: the appended section's title does not duplicate any existing section title in the original.
- [ ] **Lead with the conclusion**: same as `/aim-add` (first sentence of each paragraph is the conclusion).
- [ ] **Hard information intact**: version numbers, paths, and commands are preserved verbatim.
- [ ] **Temporal tags present**: temporary/unconfirmed items are annotated.
- [ ] **Length appropriate**: within the 300-1500 word range (if exceeded, the user was prompted to use `/aim-add`).

If any item fails, revise before proceeding to Step 8.

#### 7.8 Render the HTML Section

Once the self-check passes, wrap the content in the appendix template:

```html
<section class="appendix">
  <h2>{{SECTION_TITLE}}</h2>
  <p class="meta">Appended by {{USER_NAME}} ({{USER_ID}}) @ {{TODAY}}</p>
  {{CONTENT}}
</section>
```

If this is a cross-user operation, add the `data-cross-user` attribute and an inline annotation.

### Step 8: Insert into the Document

1. Read the target HTML file in full.
2. Locate the metadata block at the end (`<div class="highlight">Document metadata...</div>`).
3. Insert the new section immediately **before** the metadata block.
4. Update the metadata header comment:
   - Increment `version` by 1.
   - Set `updated` to today's date.
5. Save the file (atomic write: tmp + rename).

### Step 9: Update INDEX.yaml

For the target document entry:

- `version`: increment by 1.
- `updated`: today's date.
- `last_modified_by`: the current user.
- `tokens`: recalculate from the new file size.
- If the user is not yet listed in `contributors`, add them:
  ```yaml
  contributors:
    - { user: "u-a3b2f1c9", name: "Bob", last: "2026-06-21" }
  ```

Update the top-level `updated` to today's date.

### Step 10: Git Commit (Optional)

If inside a git repository:

```
git add <filename> INDEX.yaml
git commit -m "[aim-append] <PROJECT_NAME> - append <SECTION_TITLE> to <filename> [cross-user:from <name>] (doc:<DOC_ID>)"
```

Only include `[cross-user:from <name>]` when applicable.

### Step 11: Output Result

```
Done - content appended.

Operation details
   Target document: Auth Module Design (aim-20260621-a3b2f1)
   Appended section: Update - 2026-06-21
   Operator: Bob (u-a3b2f1c9)
   Version: 1 -> 2

Files
   /Users/.../2026-06-21-auth-module-design.html

Next steps
   - /aim-status     View updated document state
   - /aim-edit       If you need to modify existing content
```

## Edge Cases

### Case A: Target document is compressed/archived

- Cannot append to compressed documents (owned by `__project__`, frozen state).
- Suggestion: use `/aim-add` to create a new document with the new content instead.

### Case B: Document file is corrupted (no metadata header)

- Detection: unable to parse `<!-- aim:... -->`.
- Halt: `Document metadata missing; file may be corrupted. Run /aim-rebuild to repair, then retry.`

### Case C: Cross-user confirmation declined

- Clean abort. No files are modified.

### Case D: Content is too large (single append exceeds 3000 tokens)

- Warning: `Append content is large (X tokens). Consider splitting into a standalone document via /aim-add. Continue anyway? (Y/n)`

### Case E: Document version is high (>10)

- After many appends, suggest: `This document has been appended 10+ times. Consider /aim-compress to consolidate into a compressed document.`

## Output Style

- Use English throughout.
- Display the version number increment explicitly.
- For cross-user operations, always display the cross-user annotation in the output.
- Emoji: ✅ 📋 📁 📝 ⚠️

## Soft Sandbox Behavior

- Own documents: append freely, no confirmation required.
- Another user's documents: explicit confirmation every time, no caching.
- Compressed documents (`owner=__project__`): treated as cross-user for everyone (since they are shared).

## References

- Related commands: `/aim-add`, `/aim-edit`, `/aim-archive`
- Concept: `reference/soft-sandbox.md`
