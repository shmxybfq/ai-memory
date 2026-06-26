---
name: aim-edit
description: Edit existing content in a document. Unlike /aim-append (append-only), /aim-edit modifies existing sections. Triggers cross-user confirmation if not the owner. Always preserves the original via snapshot backup.
---

# /aim-edit — Edit Existing Document

## Purpose

Modify existing content in a document — fix errors, update outdated information, restructure sections. Unlike `/aim-append` (append-only), `/aim-edit` can rewrite or delete existing sections.

**Safety mechanisms**:
1. Always backs up the original file to `snapshots/YYYY-MM-DD/` before editing.
2. Non-owners require cross-user confirmation.
3. Original metadata `version` is incremented; `last_modified_by` is updated.

Typical use cases:
- The document contains incorrect information
- A decision has changed and the document needs to reflect the update
- Restructuring for clarity (not just adding content)

## Usage

```
/aim-edit <doc_id|filename> [--section <heading>] [instructions]
```

- `doc_id` or filename: the target document.
- `--section <heading>`: limit the edit to a specific section (matched by heading text).
- `instructions`: natural language describing what to change.

If no `instructions` are provided: interactively prompt the user.

## Prerequisites

Default (see SKILL.md §G3). Additional:
- Target document exists in the `active` list

## Workflow

### Steps 1-4: Parse project, identity, document, and sandbox check

Steps 1-2 follow SKILL.md §G1 (project) + §G2 (identity). Steps 3-4: resolve target document and sandbox check, same as `/aim-append` steps 3-4. Cross-user confirmation applies.

### Step 5: Snapshot Backup (Always Executed)

Before editing:

1. Create snapshot directory: `<root>/snapshots/YYYY-MM-DD/` (mkdir -p).
2. **Copy** (not move) the current file to `snapshots/YYYY-MM-DD/<original-filename>`.
3. This copy serves as the pre-edit backup.

The active file stays in place (it gets modified in-place), but the pre-edit version is preserved as a snapshot.

### Step 6: Collect Edit Instructions

If the `instructions` argument is provided: use it directly.

Otherwise, prompt:

```
Please describe the changes you want to make (natural language is fine, e.g. "change the JWT implementation in section 3 to use the jose library"):
[wait for user input]
```

### Step 7: Determine Edit Scope

If `--section` is provided:
- Locate the section by heading text (case-insensitive partial match).
- All modifications are confined to that section.
- If section is not found: `Section [xxx] not found. Sections in document: [list]`.

Otherwise: edit anywhere in the full document.

### Step 8: Apply Edits (LLM Turn)

#### 8.1 Role Definition

**You are not "rewriting the document." You are performing surgical edits.**

The reader will compare before and after diffs. They expect to see **precise, minimal changes** — not "a version that looks better."

> **Failure mode warning**: The 5 most common LLM failures when editing documents — tangential restructuring of unrelated content, altering the original tone/style, inflating concise text (or the reverse), deleting content that should be kept, and changing semantics while treating it as a mere wording adjustment.

#### 8.2 Required Principles (MUST Follow)

1. **Minimal diff principle**: Change only what the user asked to change. Do not opportunistically optimize other parts.
2. **Semantic preservation**: You may condense or rephrase wording, but you **must not reverse conclusions** (if the original says "choose A", you cannot change it to "choose B" unless the user explicitly asks).
3. **Style preservation**: Do not alter the original's tone, voice, terminology, or register.
4. **Metadata header protection**: Inside `<!-- aim:... -->`, only the `version` and `updated` fields may be changed.
5. **Scope isolation**: If `--section` was given, never touch any other section.

#### 8.3 Prohibited Behaviors (MUST NOT)

1. **No opportunistic restructuring**: Do not "while I'm editing this, I'll clean up that too."
2. **No style beautification**: Do not convert lists to tables, or expand short sentences into long ones (unless the user explicitly asks).
3. **No expansion**: Do not "add some useful context."
4. **No deletion of hard information**: Version numbers, paths, commands, and configuration values must never be deleted even if they appear outdated — mark them with `[deprecated]` instead.
5. **No structural changes**: Section order and heading hierarchy must remain unchanged (unless the user explicitly requests reorganization).
6. **No fabrication of reasons**: If the user says "change it to X," do not add your own reasoning like "because Y."

#### 8.4 Edit Types and Corresponding Strategies

**Type A: Factual correction** (version number, config value, or command name changed)
```
Original: We use the jsonwebtoken library
Edit: We use the jose library (v5.0.0)
Strategy: Replace directly; explain the reason in the commit message.
```

**Type B: Decision change** (an old decision is superseded by a new one)
```
Original: Adopted approach A, because X
Edit: Adopted approach B, because Y. Approach A is deprecated.
Strategy: Do not delete the original decision outright. Mark it as
          [deprecated - replaced by X @ YYYY-MM-DD], or move it
          into a <details> collapsible block.
```

**Type C: Supplementary information** (existing content was incomplete)
```
Original: We use JWT
Edit: We use JWT (specifically: Access Token 15min + Refresh Token 7d)
Strategy: Supplement in-place, preserving the original paragraph structure.
```

**Type D: Content removal** (existing content is outdated)
```
Original: [some outdated content]
Edit: [deprecated @ YYYY-MM-DD] Reason: XXX
Strategy: Never delete directly. Move to a <details> collapsible block (soft delete).
```

**Type E: Structural reorganization** (user explicitly requests section reorder)
```
Original: [Section A -> Section B -> Section C]
Edit: [Section B -> Section A -> Section C]
Strategy: Confirm the user's intent (this is a high-impact change). A diff preview must be shown.
```

#### 8.5 Counter-Examples

**Counter-example 1: Opportunistic restructuring**

Wrong (user only asked to update a version number):
```
(While updating the version number, the entire section was rewritten, paragraphs were merged, and terminology was changed.)
```

Correct:
```
(Only the version number string was changed. Everything else is untouched.)
```

**Counter-example 2: Reversing semantics**

Wrong (user said "tweak the wording"):
```
Original: Approach A is a temporary choice; we plan to migrate to B long-term.
Edit: Approach A is the final choice.
(The conclusion was reversed!)
```

Correct:
```
Original: Approach A is a temporary choice; we plan to migrate to B long-term.
Edit: Approach A is an interim solution; we plan to migrate to B in Q3.
(Only the phrasing was adjusted. The meaning is unchanged.)
```

**Counter-example 3: Deleting hard information**

Wrong (user said "clean up the outdated commands"):
```
The `git flow feature finish` command was deleted entirely.
```

Correct:
```
[deprecated @ 2026-06-21] Reason: Migrated to GitHub PR workflow.
<code>git flow feature finish</code>
```

**Counter-example 4: Expanding beyond scope**

Wrong (user said "add a bit more detail about X"):
```
(Added 5 paragraphs of background, 3 examples, and 2 tables at the X location.)
```

Correct:
```
(Added 1-2 sentences of necessary detail at the X location. Enough to be useful, nothing more.)
```

**Counter-example 5: Fabricating reasons**

Wrong (user said "change JWT to jose"):
```
(The edit also added: "because jsonwebtoken is no longer maintained.")
```

Correct:
```
(Only the library name was changed. No reason was fabricated — the user didn't mention one.
 Or, if needed, noted in the commit message: "Reason: user requested; no explanation given.")
```

#### 8.6 Self-Check Checklist (Must Complete Before Diff Preview)

After completing the edit, Claude checks itself:

- [ ] **Minimal diff**: Are all changes exactly what the user requested? Any opportunistic optimizations?
- [ ] **Semantic preservation**: Were any original conclusions reversed?
- [ ] **Style preservation**: Was the original's tone, terminology, or structure altered?
- [ ] **Hard information protected**: Were any version numbers, paths, commands, or config values deleted or rewritten?
- [ ] **Soft deletion**: Was deleted content marked with `[deprecated]` rather than removed outright?
- [ ] **Scope isolation**: If `--section` was given, were any other sections touched?
- [ ] **No fabrication**: Were any "reasons," "background," or "examples" invented and added?

If any item fails: revise before proceeding to Step 9 (diff preview).

#### 8.7 Generate New HTML

After passing self-check, generate the complete edited HTML content and prepare for Step 9 (diff preview).

### Step 9: Diff Preview

Show a unified diff to the user before writing:

```
Edit Preview

File: 2026-06-21-auth-module-design.html
Scope: Full document (--section not specified)

```diff
- We use the jsonwebtoken library to sign tokens.
+ We use the jose library to sign tokens (more modern, supports more algorithms).
```

Apply changes? (Y/n/e[manual edit])
```

- `Y`: write the changes.
- `n`: abort.
- `e`: open the file in the user's `$EDITOR` for manual editing.

### Step 10: Write File

Atomic write (tmp + rename). Update the metadata header:
- `version` += 1
- `updated` = today

### Step 11: Update INDEX.yaml

Same as `/aim-append` step 9:
- version incremented
- updated = today
- last_modified_by = current user
- tokens recalculated
- contributors updated

Additionally, append to the `snapshots` list:

```yaml
- date: "2026-06-21"
  reason: "pre-edit-backup"
  files:
    - "2026-06-21-auth-module-design.html"
  original_of: "aim-20260621-a3b2f1"
  edited_by: "u-a3b2f1c9"
```

### Step 12: Git Commit (Optional)

```
git add <filename> INDEX.yaml snapshots/
git commit -m "[aim-edit] <PROJECT_NAME> - edited <filename> [cross-user:from <name>] (doc:<DOC_ID>)"
```

### Step 13: Output Results

```
Document edited successfully

Operation Details
   Target: Auth Module Design (aim-20260621-a3b2f1)
   Scope: Full document / Section [xxx]
   Edited by: Zhu Taofeng (u-a3b2f1c9)
   Version: 2 -> 3

Files
   Current: /Users/.../2026-06-21-auth-module-design.html
   Backup:  /Users/.../snapshots/2026-06-21/2026-06-21-auth-module-design.html

Next Steps
   - /aim-status              View updated project status
   - /aim-expand <doc_id>     Compare with historical versions
```

## Edge Cases

### Case A: Ambiguous edit instructions

- The LLM may produce multiple interpretations.
- Present all interpretations and let the user choose: `Please select how you want the edit applied: 1) ... 2) ...`.

### Case B: Edit would delete a large amount of content

- Warn before applying: `This edit will remove approximately N characters of content. Would you prefer to mark them as [deprecated] and collapse instead? (Y/n)`.

### Case C: Cross-user edit on a highly-owned document

- Stronger warning: `This is [Zhang San]'s core document. Your changes will affect the team's shared understanding of it. Confirm?`.

### Case D: Snapshot directory already contains a file with the same name (multiple edits in one day)

- Append a `-N` suffix to the backup filename.

### Case E: Edit is cancelled after the snapshot was taken

- The snapshot is harmless (it is merely a pre-edit backup).
- Notify: `A pre-edit snapshot has been preserved at snapshots/YYYY-MM-DD/xxx. You can manually delete it if not needed.`.

### Case F: Target is a compressed document

- Block the operation: `Compressed documents cannot be edited directly with /aim-edit. To update their content, create a new document with /aim-add, then run /aim-compress to merge incrementally.`.

## Output Style

_Defaults from SKILL.md §G4 apply._ Additional:

- Display diffs in monospaced code blocks.
- Always display the backup path.
- Cross-user edits: display cross-user marker prominently.
- Emoji usage: specific emoji reserved for consistent visual markers.

## Deviations from Global Rules

- Compressed documents: direct editing is prohibited (use `/aim-add` + `/aim-compress` instead).

## References

- Companion commands: `/aim-append`, `/aim-archive`, `/aim-expand`
- Concepts: `reference/soft-sandbox.md`, `reference/document-lifecycle.md`
