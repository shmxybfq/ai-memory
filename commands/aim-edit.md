---
name: aim-edit
description: Modify existing content in a document. Unlike /aim-append (which only adds), /aim-edit changes existing sections. Triggers cross-user confirmation if not owner. Always preserves original via snapshot backup.
---

# /aim-edit — Modify Existing Document

## Purpose

Change existing content in a document — fix errors, update outdated info, refactor structure. Unlike `/aim-append` (additive only), `/aim-edit` can rewrite or remove existing sections.

**Safety mechanisms**:
1. Always backs up the original to `snapshots/YYYY-MM-DD/` before editing.
2. Cross-user confirmation required if not owner.
3. Original metadata `version` bumps; `last_modified_by` updates.

Use this command when:
- A doc has incorrect information
- A decision was updated and the doc needs to reflect it
- Restructuring for clarity (not just adding)

## Usage

```
/aim-edit <doc_id|filename> [--section <heading>] [instructions]
```

- `doc_id` or `filename`: target document.
- `--section <heading>`: limit edit to a specific section (by heading text).
- `instructions`: natural language description of what to change.

If no instructions: prompt user interactively.

## Prerequisites

- Project initialized.
- Target document exists in `active` list.
- User identity established.

## Flow

### Step 1-4: Resolve Project, Identity, Document, Sandbox Check

Same as `/aim-append` Steps 1-4. Cross-user confirmation applies.

### Step 5: Snapshot Backup (Always)

Before any edit:

1. Create snapshot dir: `<root>/snapshots/YYYY-MM-DD/` (mkdir -p).
2. Copy (not move) the current file to `snapshots/YYYY-MM-DD/<original-filename>`.
3. The copy serves as the pre-edit backup.

This way the active file stays in place (just modified), but a snapshot of the pre-edit version is preserved.

### Step 6: Collect Edit Instructions

If `instructions` argument provided: use directly.

Otherwise prompt:

```
请描述要做的修改(自然语言即可,如「把第三段的 JWT 实现改为使用 jose 库」):
[等待用户输入]
```

### Step 7: Determine Edit Scope

If `--section` provided:
- Locate the section by heading text (case-insensitive partial match).
- Restrict all modifications to within that section's bounds.
- If section not found: `未找到章节 [xxx]。文档中的章节: [list]`。

Otherwise: edit anywhere in the doc.

### Step 8: Apply Edits (LLM Pass)

Read the document fully. Apply the requested changes.

**Rules for editing**:
1. Preserve metadata header (`<!-- aim:... -->`) — only the version/updated fields may change.
2. Don't touch other sections outside `--section` scope.
3. Don't rewrite the entire doc — minimal diff is preferred.
4. If removing content: move it to a `<details>` collapsed block at the end of the section with `[deprecated @ YYYY-MM-DD]` note, rather than deleting outright. Soft delete.
5. If adding new content: insert at semantically appropriate location.

Generate the new HTML content.

### Step 9: Diff Preview

Show the user a unified diff before writing:

```
📋 修改预览

文件: 2026-06-21-auth-module-design.html
范围: 全文(未限定 --section)

```diff
- 我们使用 jsonwebtoken 库来签发 token。
+ 我们使用 jose 库来签发 token(更现代,支持更多算法)。
```

是否应用? (Y/n/e[手动编辑])
```

- `Y`: write changes.
- `n`: abort.
- `e`: open the file in user's `$EDITOR` for manual editing.

### Step 10: Write File

Atomic write (tmp + rename). Update metadata header:
- `version` += 1
- `updated` = today

### Step 11: Update INDEX.yaml

Same as `/aim-append` Step 9:
- version bump
- updated = today
- last_modified_by = current user
- tokens recompute
- contributors update

Also append to `snapshots` list:

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
git commit -m "[aim-edit] <PROJECT_NAME> - 修改 <filename> [cross-user:from <name>] (doc:<DOC_ID>)"
```

### Step 13: Output Result

```
✅ 文档已修改

📋 操作信息
   目标文档: 认证模块设计 (aim-20260621-a3b2f1)
   修改范围: 全文 / 章节 [xxx]
   操作者: 朱陶锋 (u-a3b2f1c9)
   版本: 2 → 3

📁 文件
   当前: /Users/.../2026-06-21-auth-module-design.html
   备份: /Users/.../snapshots/2026-06-21/2026-06-21-auth-module-design.html

📝 下一步
   - /aim-status              查看更新后状态
   - /aim-expand <doc_id>     对比历史版本
```

## Edge Cases

### Case A: Edit instructions ambiguous

- LLM may produce multiple interpretations.
- Show all interpretations, ask user to pick: `请选择你想要的修改方式: 1) ... 2) ...`。

### Case B: Edit would remove large chunk of content

- Warn before applying: `本次修改将删除约 N 字内容。建议改为标 [deprecated] 折叠保留? (Y/n)`。

### Case C: Cross-user edit on highly-owned doc

- Stronger warning: `这是 [张三] 的核心文档,你的修改会影响团队对它的理解。确认?`

### Case D: Snapshot dir already has same-named file (multiple edits same day)

- Append `-N` suffix to backup filename.

### Case E: Edit cancelled after snapshot taken

- The snapshot is harmless (it's just a backup of the pre-edit state).
- Note: `已保留 pre-edit 快照(snapshots/YYYY-MM-DD/xxx),如不需要可手动删除`。

### Case F: Target is the compressed doc

- Block: `压缩文档不可直接 /aim-edit。如需更新内容,先 /aim-add 新文档,再 /aim-compress 增量合并`。

## Output Style

- Chinese throughout.
- Show diff in monospace block.
- Always show backup path.
- Cross-user edits: show the marker prominently.
- Emojis: ✅ 📋 📁 📝 ⚠️

## Soft Sandbox Behavior

- Own docs: free edit, just snapshot backup.
- Others' docs: cross-user confirmation every time.
- Compressed doc: blocked from direct edit.

## Reference

- Companion commands: `/aim-append`, `/aim-archive`, `/aim-expand`
- Concept: `reference/soft-sandbox.md`, `reference/document-lifecycle.md`
