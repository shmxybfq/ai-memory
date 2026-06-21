---
name: aim-expand
description: Reverse-search snapshots for original detail of a compressed topic. Reads archived docs that fed into the compressed file. Read-only retrieval.
---

# /aim-expand — Retrieve Archived Detail

## Purpose

After `/aim-compress`, source documents are archived to `snapshots/`. The compressed doc keeps the consolidated view, but detail is lost. `/aim-expand` lets you pull the original detail back when needed.

Typical use:
- Compressed doc says "我们曾考虑方案 A 和 B,选了 B"
- You want to know *why* A was rejected
- `/aim-expand <compressed_doc_id> topic=方案 A 对比` → fetches original discussion from snapshots

**Read-only.** Never modifies snapshots or compressed doc.

## Usage

```
/aim-expand <doc_id|filename> [--topic <keyword>] [--date <YYYY-MM-DD>]
```

- `doc_id` or filename: which compressed doc to expand (or which snapshot to read).
- `--topic`: keyword to search within snapshots (e.g., `认证`, `路由`).
- `--date`: limit to a specific snapshot date.

If no compressed doc currently exists, `/aim-expand` lists available snapshots instead.

## Prerequisites

- Project initialized.
- At least one snapshot exists OR a compressed doc with archive zone.

## Flow

### Step 1: Resolve Current Project

Same logic as `/aim-status` Step 1.

### Step 2: Determine Target

If `<doc_id>` argument provided:
- If it matches the current compressed doc: target = compressed doc + all snapshots that fed into it.
- If it matches a snapshot file: target = that single snapshot.

If no argument:
- List all snapshots with date and brief content summary.
- Ask user which to expand.

### Step 3: Identify Snapshot Pool

For compressed doc target:
1. Read `INDEX.yaml` `compressed[0].sources` (if recorded) — explicit list of source doc_ids.
2. If not recorded (older compress runs), fall back: scan all `snapshots/*/` and use date proximity to compressed doc's `created`.

For single snapshot target: just that one file.

### Step 4: Filter by Topic (if --topic provided)

For each snapshot file in the pool:
1. Read content.
2. Search for the topic keyword (case-insensitive, also match Chinese variants).
3. Score relevance (count of matches, position in doc).
4. Rank by relevance.

If `--topic` not provided: include all snapshots in the pool.

### Step 5: Extract Relevant Sections

For each relevant snapshot:
- Extract paragraphs/sections containing the topic.
- Preserve original formatting (HTML).
- Note the source: `<snapshot_date>/<file>.html`, original title, original author.

### Step 6: Also Check Compressed Archive Zone

The compressed doc itself has an archive zone (deprecated content). Search there too — sometimes the detail you want is in there rather than in snapshots.

### Step 7: Output

Format as a reading-friendly view:

```
🔍 展开: 方案 A 对比

📌 来源(共 3 篇)

━━━ 1. 认证模块设计 (2026-06-21) ━━━
作者: 朱陶锋 (u-a3b2f1c9)
原文件: snapshots/2026-06-21/2026-06-21-auth-module-design.html

[相关段落]
我们考虑了三种认证方案:
- 方案 A: Session + Cookie(传统,但移动端不友好)
- 方案 B: JWT + Refresh(无状态,适合多端) ← 最终选择
- 方案 C: OAuth 2.0 全套(过度设计,内部系统不需要)

[决策记录]
排除 A 的原因:移动端 cookie 处理复杂,且与 RN WebView 兼容性差。

━━━ 2. 早期 API 设计 (2026-06-15) ━━━
作者: 朱陶锋 (u-a3b2f1c9)
原文件: snapshots/2026-06-21/2026-06-15-early-api.html

[相关段落]
... (其他相关内容)

━━━ 3. [归档区] 旧版认证设计 (2026-05-20) ━━━
出处: 压缩文档归档区
状态: deprecated (被 2026-06-21 替代)

[相关段落]
...(已归档的旧版方案)

💡 提示
  - 这些是原始内容,可能与压缩文档表述不同
  - 如需引用,请使用原 doc_id 标注来源
```

### Step 8: Optional Follow-up

Offer next steps at the end:

```
下一步:
  - /aim-expand <doc_id> --topic <其他关键词>  查其他主题
  - /aim-status                              返回项目状态
```

## Edge Cases

### Case A: No snapshots exist (project never compressed)

```
尚未有快照。运行 /aim-compress 后才会产生归档。
```

### Case B: Topic not found in any snapshot

```
未在快照中找到与「xxx」相关的内容。

建议:
  - 尝试更宽泛的关键词
  - 列出所有快照: /aim-expand(不带参数)
```

### Case C: Snapshot file referenced in INDEX is missing on disk

- Skip that file.
- Note: `⚠️ 快照 xxx 已从磁盘删除,无法展开`。

### Case D: Compressed doc has no archive zone (fresh compress, no deprecated content yet)

- Just search snapshots.
- Note: `当前压缩文档无归档区内容`。

### Case E: Many snapshots match (>10)

- Show top 5 by relevance.
- Note: `找到 N 篇相关,显示前 5 篇。如需全部,使用 --limit all`。

### Case F: Cross-date expansion (user wants to compare across compressions)

- If `--date` specified, restrict to that date.
- If user wants compare mode: `/aim-expand <doc> --topic xxx --compare-dates 2026-05-01,2026-06-01` → show same topic from both snapshots side by side.

## Output Style

- Use Chinese throughout.
- Use horizontal rules (━━━) to separate sources.
- Always show: author, original filename, snapshot date.
- Preserve original HTML formatting within extracted sections.
- Quote old text with clear `[相关段落]` markers.
- End with 💡 提示 and next-step suggestions.

## Soft Sandbox Behavior

- Public command — no restrictions.
- Can read any snapshot regardless of owner (snapshots are project history, public by nature).

## Reference

- Companion commands: `/aim-compress`, `/aim-status`, `/aim-archive`
- Concept: `reference/document-lifecycle.md`
