---
name: aim-append
description: Append a new section to an existing document. Preserves original content, adds new section at the end. Triggers cross-user confirmation if doc owner differs.
---

# /aim-append — Append to Existing Document

## Purpose

Add a new section to the end of an existing document, leaving the original content untouched. Useful for:
- Adding updates to a decision log
- Recording follow-up debugging notes
- Adding new findings to an investigation doc

Differs from `/aim-edit` (which modifies existing content) and `/aim-add` (which creates a new file).

## Usage

```
/aim-append <doc_id|filename> [content]
```

- `doc_id` or `filename`: target document.
- `content`: optional, the new section content. If omitted, prompt user.

## Prerequisites

- Project initialized.
- Target document exists (in INDEX.yaml `active` list, file on disk).
- User identity established.

## Flow

### Step 1: Resolve Current Project

Same as `/aim-add` Step 1.

### Step 2: Resolve User Identity

Read `~/.claude/ai-memory/identity.json`. Required.

### Step 3: Resolve Target Document

Match `<doc_id|filename>` argument:
1. Try exact `doc_id` match in INDEX.yaml `active`.
2. Try filename match (basename).
3. Try partial title match (interactive confirm if multiple).

If not found in active: also check compressed doc's archive zone (cannot append to archived — suggest `/aim-expand` first or `/aim-add` instead).

If not found anywhere: `文档 [xxx] 不存在。/aim-list 查看所有文档`。

Save target entry as `DOC`.

### Step 4: Check Soft Sandbox (Cross-User)

Compare `DOC.owner` to current user ID.

**If same user**: proceed without confirmation.

**If different user** (cross-sandbox):

```
⚠️ 跨用户操作

文档 [xxx] 的 owner 是 [张三] (u-b1c2d3e4)。
你 [朱陶锋] (u-a3b2f1c9) 不是 owner。

是否确认追加内容到他人文档?
本次操作会在文档中标注 [cross-user:from 朱陶锋 @ 2026-06-21]。

确认? (Y/n)
```

Per project rule: no caching, every cross-user op requires fresh confirmation.

**If declined**: abort with `操作已取消`。

### Step 5: Collect New Section Content

If argument provided: use as `RAW_CONTENT`.
Otherwise prompt:

```
请输入要追加的内容(可以是补充说明、新发现、后续进展等):
[等待用户输入]
```

### Step 6: Determine Section Metadata

Ask user (with sensible defaults):

```
章节标题(可选,默认「更新 - YYYY-MM-DD」):
```

Save as `SECTION_TITLE`.

### Step 7: Generate HTML Section

Structure RAW_CONTENT into a self-contained HTML section:

```html
<section class="appendix">
  <h2>{{SECTION_TITLE}}</h2>
  <p class="meta">追加 by {{USER_NAME}} ({{USER_ID}}) @ {{TODAY}}</p>
  {{CONTENT}}
</section>
```

If cross-user, add `data-cross-user` attribute and inline note.

### Step 8: Insert into Document

1. Read target HTML file fully.
2. Find the metadata block at the end (`<div class="highlight">文档元数据...</div>`).
3. Insert the new section **before** the metadata block.
4. Update the metadata header comment:
   - Bump `version` by 1.
   - Update `updated` to today.
5. Save the file (atomic write: tmp + rename).

### Step 9: Update INDEX.yaml

For the target doc entry:
- `version`: increment by 1.
- `updated`: today.
- `last_modified_by`: current user.
- `tokens`: recompute from new file size.
- Add to `contributors` if user not already listed:
  ```yaml
  contributors:
    - { user: "u-a3b2f1c9", name: "朱陶锋", last: "2026-06-21" }
  ```

Update top-level `updated` to today.

### Step 10: Git Commit (Optional)

If in git:

```
git add <filename> INDEX.yaml
git commit -m "[aim-append] <PROJECT_NAME> - 追加 <SECTION_TITLE> 到 <filename> [cross-user:from <name>] (doc:<DOC_ID>)"
```

Only include `[cross-user:from <name>]` if applicable.

### Step 11: Output Result

```
✅ 已追加内容

📋 操作信息
   目标文档: 认证模块设计 (aim-20260621-a3b2f1)
   追加章节: 更新 - 2026-06-21
   操作者: 朱陶锋 (u-a3b2f1c9)
   版本: 1 → 2

📁 文件
   /Users/.../2026-06-21-auth-module-design.html

📝 下一步
   - /aim-status     查看更新后状态
   - /aim-edit       如需修改已有内容
```

## Edge Cases

### Case A: Target document is in compressed/archived state

- Cannot append to compressed (it's `__project__`-owned, frozen).
- Suggest: `/aim-add` to create a new doc with the new content instead.

### Case B: Document file is corrupted (no metadata header)

- Detect: cannot parse `<!-- aim:... -->`.
- Stop: `文档元数据缺失,可能损坏。运行 /aim-rebuild 修复后再试`。

### Case C: Cross-user confirmation declined

- Abort cleanly. No file changes.

### Case D: Content too large (>3000 tokens for a single append)

- Warn: `追加内容较长(X tokens),建议拆分为独立文档 /aim-add。是否继续? (Y/n)`。

### Case E: Document version gets high (>10)

- After many appends, suggest: `文档已追加 10+ 次,建议 /aim-compress 整合到压缩文档`。

## Output Style

- Chinese throughout.
- Show version bump explicitly.
- Cross-user operations: always show the cross-user marker in output.
- Emojis: ✅ 📋 📁 📝 ⚠️

## Soft Sandbox Behavior

- Own docs: free append, no confirmation.
- Others' docs: explicit confirmation every time, no caching.
- Compressed doc (`owner=__project__`): treated as cross-user for everyone (since it's shared).

## Reference

- Companion commands: `/aim-add`, `/aim-edit`, `/aim-archive`
- Concept: `reference/soft-sandbox.md`
