---
name: aim-verify
description: Check INDEX.yaml against filesystem for consistency. Reports orphans, missing files, metadata mismatches, and broken cross-references. Read-only diagnostic.
---

# /aim-verify — Consistency Check

## Purpose

Audit the project memory for consistency between `INDEX.yaml` and the filesystem. Detects:
- Orphan files (on disk but not in INDEX)
- Missing files (in INDEX but not on disk)
- Metadata drift (INDEX fields disagree with file headers)
- Broken cross-references (snapshots pointing nowhere, compressed doc missing sources)
- Token miscalculations (INDEX tokens vs actual estimate)

**Read-only.** Never modifies anything. Pair with `/aim-rebuild` to fix issues found here.

Use this command:
- After `/aim-rebuild` to confirm it worked correctly
- Periodically as a health check
- When `/aim-status` shows anomalies
- Before compression to ensure clean state

## Usage

```
/aim-verify [--fix]
```

- No argument: report only.
- `--fix`: prompt to apply safe automatic fixes (update stale INDEX fields, remove broken entries). Unsafe fixes still require manual intervention.

## Prerequisites

- Project initialized.
- INDEX.yaml parseable (if not, suggest `/aim-rebuild` first).

## Flow

### Step 1: Resolve Current Project

Same logic as `/aim-status` Step 1.

### Step 2: Parse INDEX.yaml

If parse fails: stop with `INDEX.yaml 解析失败,请先运行 /aim-rebuild 修复`.

### Step 3: Verify Each Active Entry

For each entry in `INDEX.yaml` `active`:

1. **File existence**: does `<root>/<file>` exist?
   - Missing → record `MISSING_FILE` error.
2. **Metadata match**: read HTML header, compare to INDEX fields:
   - `doc_id` must match
   - `title` should match (warn if differs)
   - `owner` must match
   - `status` must be `active`
   - `version` should match
3. **Token accuracy**: recompute tokens from file size, compare to INDEX `tokens` field.
   - Warn if delta > 20% (INDEX is stale).
4. **Contributor consistency**: every name in `contributors` should resolve via identity.json or git config.
5. **Date sanity**: `created <= updated`, both reasonable (not in future, not before project init).

### Step 4: Verify Compressed Entry

For `INDEX.yaml` `compressed`:

1. File exists at `<root>/<compressed-file>`?
2. Metadata header has `owner=__project__`?
3. The archive section references doc_ids — do any of them still exist as active files? (Would indicate an incomplete compress operation.)
4. Token estimate vs actual file size sanity check.

### Step 5: Verify Snapshots

For each `INDEX.yaml` `snapshots` entry:

1. Directory `<root>/snapshots/<date>/` exists?
2. File count matches INDEX?
3. Each file inside has valid metadata?

Also scan filesystem `<root>/snapshots/*/` for dirs not in INDEX (orphans).

### Step 6: Scan for Orphan Files

Walk `<root>/*.html` (and distributed: `<project>/.ai-memory/*.html`):

- Any HTML file with valid `<!-- aim:... -->` header but not in any INDEX list → orphan.
- Any HTML file without metadata header → unmanaged (suggest user delete or add metadata).

### Step 7: Cross-Reference Checks

- Every `doc_id` in INDEX should be unique.
- Every `file` path should be unique.
- `compressed` list should have at most one entry (single-file compression model).
- `last_modified_by` should be in `contributors` list.

### Step 8: Categorize Findings

Group issues by severity:

| Severity | Meaning | Examples |
|---|---|---|
| 🔴 ERROR | Data loss risk, must fix | Missing file, parse failure, duplicate doc_id |
| 🟠 WARN | Drift, should fix | Stale tokens, title mismatch, old backup files |
| 🟡 INFO | Informational | Orphan file (likely user-managed), unmanaged HTML |
| 🟢 OK | All checks passed | (only shown if nothing else) |

### Step 9: Apply Auto-Fixes (if --fix)

For each WARN/INFO that has a safe automatic resolution:

1. **Stale tokens**: recompute and update INDEX.
2. **Title mismatch**: take the file's title (filesystem wins).
3. **Missing `last_modified_by` in contributors**: add it.

Skip auto-fix for:
- 🔴 ERROR items (need user judgment)
- Orphan files (might be intentional)
- Anything that would delete content

Before writing, show the proposed changes and ask for confirmation:

```
📋 准备自动修复 3 项

1. aim-20260620-xxx: tokens 800 → 920 (重新计算)
2. aim-20260615-yyy: title 「旧」→「新」(从文件头读取)
3. aim-20260610-zzz: 添加 contributor u-b1c2d3e4

确认执行? (Y/n)
```

Backup INDEX.yaml before writing (same as `/aim-rebuild`).

### Step 10: Output Report

```
🔍 一致性检查报告

📊 总览
   检查项: 24
   通过: 21
   警告: 2
   错误: 1

🔴 错误 (1)
   1. [MISSING_FILE] aim-20260610-yyy
      INDEX 记录文件 `2026-06-10-old.html`,但文件不存在
      建议: 从 git 恢复,或运行 /aim-rebuild 移除此条目

🟠 警告 (2)
   1. [TOKEN_STALE] aim-20260620-xxx
      INDEX 记录 800 tokens,实际约 920 tokens
      建议: 运行 /aim-verify --fix 自动更新
   2. [TITLE_DRIFT] aim-20260615-yyy
      INDEX: 「旧标题」,文件头: 「新标题」
      建议: 运行 /aim-verify --fix 以文件为准

🟡 提示 (1)
   1. [ORPHAN_FILE] old-notes.html
      文件存在但未纳入 INDEX,可能手动添加
      建议: 如需管理,运行 /aim-add 重新登记

🟢 通过的检查 (21 项)
   ✅ 所有 doc_id 唯一
   ✅ 所有 file 路径唯一
   ✅ compressed 文档完整
   ✅ snapshots 目录一致
   ...

📝 下一步
   - /aim-verify --fix    自动修复可修复项
   - /aim-rebuild         完全重建 INDEX
   - 手动处理错误项后再次运行 /aim-verify
```

## Edge Cases

### Case A: INDEX.yaml itself fails to parse

- Stop immediately.
- Suggest: `INDEX.yaml 解析失败,请运行 /aim-rebuild`。
- Do not attempt partial verification.

### Case B: Project has zero active docs and zero compressed

- Valid state (freshly initialized).
- Report: `🟢 项目为空,无内容可检查`

### Case C: identity.json missing

- Cannot resolve contributor names.
- Warn but continue: `无法解析用户名,以 ID 形式显示`

### Case D: Git history available

- Optionally cross-reference `last_modified_by` with actual git committer.
- If they disagree: 🟠 WARN (INDEX may be stale).

### Case E: --fix encounters unsafe change mid-run

- Abort the entire fix batch (don't apply partial fixes).
- Restore from backup if any write happened.
- Report what was attempted and why it was aborted.

### Case F: Network required for some check (e.g., identity sync)

- Skip that check, note in report: `跳过 X 检查 (需要网络)`

## Output Style

- Use Chinese for all labels.
- Severity emojis: 🔴 🟠 🟡 🟢
- Issue codes in `[UPPER_SNAKE_CASE]` for grep-ability.
- Align issue numbers and descriptions.
- Always show counts in 总览 section first.
- For long file lists, truncate with `... 及其他 N 项` and offer `--detail` flag.

## Soft Sandbox Behavior

- `/aim-verify` is a **public command** — no sandbox restrictions.
- Read-only by default; `--fix` mode only touches INDEX.yaml cache (not content), so still considered safe for any user.

## Reference

- Companion commands: `/aim-rebuild`, `/aim-status`
- Concept: `reference/rule-diff-verification.md`
