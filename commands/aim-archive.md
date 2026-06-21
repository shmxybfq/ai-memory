---
name: aim-archive
description: Move a document from active list to snapshots directory. Use for docs that are no longer current but should be preserved. Reversible.
---

# /aim-archive — Archive Document

## Purpose

Move an active document to the snapshots directory. The doc is no longer in the "active reading set" for new sessions, but is preserved for historical reference and `/aim-expand` retrieval.

Different from `/aim-compress`:
- `/aim-compress`: merge many docs into one compressed file, then snapshot the originals.
- `/aim-archive`: snapshot a single doc without compressing (it doesn't contribute to compressed file).

Use this command when:
- A doc is obsolete but you don't want to lose it
- A doc represents a deprecated approach you want to soft-delete
- Preparing for compression but want to exclude certain docs from the merge

**Reversible**: `/aim-expand` can read archived docs; manually moving the file back + rebuilding INDEX restores active state.

## Usage

```
/aim-archive <doc_id|filename> [--reason <text>]
```

- `doc_id` or `filename`: target document.
- `--reason <text>`: optional reason for archiving (recorded in INDEX).

## Prerequisites

- Project initialized.
- Target document exists in `active` list.
- User identity established.

## Flow

### Step 1-4: Resolve Project, Identity, Document, Sandbox Check

Same as `/aim-append` Steps 1-4.

For `/aim-archive`, cross-user confirmation applies (archiving someone else's doc affects project state).

### Step 5: Confirm Intent

Always confirm before archiving:

```
⚠️ 准备归档文档

文档: 认证模块设计 (aim-20260621-a3b2f1)
作者: 朱陶锋
创建: 2026-06-21
版本: 2

归档后:
  - 文件移至 snapshots/2026-06-21/
  - 不再出现在 /aim-status 活跃列表
  - 仍可通过 /aim-expand 检索
  - 不会纳入下次 /aim-compress 的源文档

确认归档? (Y/n)
```

### Step 6: Determine Snapshot Location

Snapshot path: `<root>/snapshots/YYYY-MM-DD/<filename>`

If file already exists there (same-day archive of same name): append `-N` suffix.

### Step 7: Move File

```
mv <root>/<filename> → <root>/snapshots/YYYY-MM-DD/<filename>
```

Use `mv` (not copy) — the doc leaves the active location.

### Step 8: Update Document Metadata

Read the moved file. Update its metadata header:

```
status=archived
archived_at=2026-06-21
archived_by=u-a3b2f1c9
archive_reason=<reason text or "manual">
```

Write back.

### Step 9: Update INDEX.yaml

1. Remove entry from `active` list.
2. Add to `snapshots` list:

```yaml
- date: "2026-06-21"
  reason: "<reason or manual>"
  files:
    - "<filename>"
  archived_from: "<doc_id>"
  archived_by: "u-a3b2f1c9"
```

3. Update top-level `updated` to today.

### Step 10: Git Commit (Optional)

```
git add snapshots/ INDEX.yaml
git rm <old active path>  # since file moved
git commit -m "[aim-archive] <PROJECT_NAME> - 归档 <filename> [cross-user:from <name>] (doc:<DOC_ID>)"
```

### Step 11: Output Result

```
✅ 文档已归档

📋 归档信息
   文档: 认证模块设计 (aim-20260621-a3b2f1)
   原因: 手动归档 / <用户输入的原因>
   操作者: 朱陶锋 (u-a3b2f1c9)

📁 文件位置
   归档至: /Users/.../snapshots/2026-06-21/2026-06-21-auth-module-design.html
   (已从活跃区移除)

📊 项目状态
   活跃: 5 篇(原 6 篇)
   压缩: 1 篇
   快照: 3 个目录

📝 下一步
   - /aim-status              查看更新后状态
   - /aim-expand <doc_id>     如需检索归档内容
   - 手动恢复: mv 文件回根目录 + /aim-rebuild
```

## Edge Cases

### Case A: Archiving the last active doc

- Allowed, but warn: `归档后项目活跃文档为 0。是否仍要继续? (Y/n)`。

### Case B: Doc has dependencies (other docs reference it)

- Scan other active docs for mentions of this doc_id or title.
- If references found: warn `以下文档引用了 [xxx]: [list]。归档后这些引用将成为死链。是否继续? (Y/n)`。

### Case C: Doc is referenced in compressed doc's archive zone

- Already preserved there. Archiving the active copy is safe.
- Note: `该文档已存在于压缩文档归档区,本次归档的是 active 副本`。

### Case D: Snapshot dir for today has many files already

- Allowed, just note: `今日快照目录已有 N 篇,建议适时 /aim-compress 整合`。

### Case E: Reason text provided is very long

- Truncate to 200 chars in INDEX.yaml. Full reason goes in the archived file's metadata.

## Output Style

- Chinese throughout.
- Always show "from → to" path transition.
- Update counts (before → after) in 项目状态.
- Emojis: ✅ 📋 📁 📊 📝 ⚠️

## Soft Sandbox Behavior

- Own docs: archive freely with one confirmation.
- Others' docs: cross-user confirmation required every time.
- Public/archived docs: N/A (already archived).

## Reference

- Companion commands: `/aim-expand` (reverse retrieval), `/aim-compress` (bulk archival via merge)
- Concept: `reference/document-lifecycle.md`
