---
name: aim-rebuild
description: Rebuild INDEX.yaml from filesystem. Use when INDEX is corrupted, out of sync, or manually edited. Reads metadata from HTML files and reconstructs the index. Safe to run anytime.
---

# /aim-rebuild — Rebuild INDEX.yaml

## Purpose

Reconstruct `INDEX.yaml` entirely from the filesystem by reading metadata headers embedded in HTML files. **The filesystem is the source of truth — INDEX.yaml is a rebuildable cache.**

Use this command when:
- INDEX.yaml is corrupted or unparseable
- INDEX.yaml was manually edited and may be inconsistent
- Files were added/removed outside of ai-memory commands (e.g., manual file ops)
- After `/aim-verify` reports drift between INDEX and filesystem
- As a recovery step after a failed/aborted operation

**Safe to run anytime.** Always backs up the old INDEX.yaml before writing.

## Usage

```
/aim-rebuild [--dry-run]
```

- `--dry-run`: Show what would change without writing. Recommended first run.
- No argument: rebuild and write.

## Prerequisites

- Project initialized (INDEX.yaml existed at some point; even if corrupted, the project dir structure must be intact).
- HTML files must have valid `<!-- aim:... -->` metadata headers.

## Flow

### Step 1: Resolve Current Project

Same logic as `/aim-status` Step 1. Read existing INDEX.yaml if possible (for project name, mode, root).

### Step 2: Backup Existing INDEX.yaml

If `INDEX.yaml` exists:

```
Copy INDEX.yaml → INDEX.yaml.bak.<YYYYMMDD-HHMMSS>
```

Keep the last 3 backups; older ones get overwritten in rotation. Never delete backups without user permission.

### Step 3: Scan Filesystem

Walk the project memory directory:

```
<root>/                          ← for distributed: <project>/.ai-memory/
├── INDEX.yaml                   ← (will be overwritten)
├── *.html                       ← active docs
├── compressed-*.html            ← compressed doc (single file)
├── snapshots/
│   ├── YYYY-MM-DD/
│   │   └── *.html               ← archived snapshots
│   └── ...
└── ...
```

For each HTML file found:

1. Read first 2KB (header section).
2. Extract metadata from the leading `<!-- aim:... -->` comment.
3. Parse key=value pairs: `doc_id`, `title`, `tags`, `created`, `created_by`, `owner`, `status`, `source`, `version`.
4. If no metadata header: flag as unmanaged file (skip from active list, report as orphan).
5. Compute tokens from file size.
6. Read git blame for `last_modified_by` and `updated` if available; otherwise fall back to file mtime.

### Step 4: Classify Files

Bucket each parsed file:

| Condition | Bucket |
|---|---|
| `owner=__project__` and filename starts with `compressed-` | `compressed` |
| `status=active` and in root or active dir | `active` |
| `status=archived` or in `snapshots/YYYY-MM-DD/` | `snapshots[YYYY-MM-DD]` |
| `status=deprecated` | listed in `compressed` archive zone (read compressed doc to verify) |
| No metadata header | orphan (report, don't include in index) |

### Step 5: Reconstruct INDEX.yaml

Build the new structure:

```yaml
project: "<from old INDEX or basename of root>"
mode: "<from old INDEX or detect: central if root is in known roots, else distributed>"
root: "<absolute path>"
created: "<from old INDEX or earliest doc created date>"
updated: "<today>"
version: 1

initialized_by:
  id: "<from old INDEX, or first doc's owner>"
  name: "<from old INDEX, or unknown>"

compressed: [<list from compressed bucket>]

active: [<list from active bucket, sorted by created desc>]

snapshots: [<list of {date, count, files} from snapshots bucket>]
```

For each `active` entry, derive fields:

```yaml
- doc_id: "<from metadata>"
  title: "<from metadata>"
  file: "<basename>"
  owner: "<from metadata>"
  owner_name: "<resolve from identity.json or git config; fallback to id>"
  created: "<from metadata>"
  created_by: "<from metadata>"
  updated: "<from file mtime or git blame>"
  last_modified_by: "<from git blame last committer, or owner>"
  version: <from metadata, default 1>
  status: "<from metadata, default active>"
  source: "<from metadata, default unknown>"
  tags: [<from metadata>]
  permission: private
  tokens: <estimated>
  contributors:
    - { user: "<owner>", name: "<resolved>", last: "<updated>" }
```

### Step 6: Dry-Run Diff (if --dry-run)

Show user what would change:

```
📋 重建预览 (--dry-run)

当前 INDEX.yaml:
  活跃: 5 篇
  压缩: 1 篇
  快照: 2 个

重建后 INDEX.yaml:
  活跃: 6 篇 (+1)
  压缩: 1 篇 (=)
  快照: 2 个 (=)

变更明细:
  + 新增到 active:
    - aim-20260621-xxx (新文档.html)
  - 从 active 移除:
    - aim-20260610-yyy (文件不存在)
  ⚠️ 字段更新:
    - aim-20260615-zzz: title 从「旧标题」改为「新标题」

是否执行重建? (Y/n)
```

Wait for confirmation. If user declines, exit without writing.

### Step 7: Write INDEX.yaml

If not dry-run, or user confirmed:

1. Write the new INDEX.yaml atomically (write to `INDEX.yaml.tmp`, then `mv`).
2. Validate by reading back and parsing.
3. If parse fails: restore from backup and abort with error.

### Step 8: Output Result

```
✅ INDEX.yaml 已重建

📋 重建结果
   活跃: 6 篇 (8,400 tokens)
   压缩: 1 篇 (12,500 tokens)
   快照: 2 个目录 (14 篇归档)

📁 文件位置
   /Users/.../INDEX.yaml
   备份: /Users/.../INDEX.yaml.bak.20260621-153022

⚠️ 注意事项
   - 1 个孤儿文件未被纳入索引: old-notes.html
   - 1 个文档丢失文件: aim-20260610-yyy (INDEX 中已移除)

📝 下一步
   - /aim-status    查看完整状态
   - /aim-verify    执行深度一致性检查
```

## Edge Cases

### Case A: Project has no HTML files at all (fresh init, INDEX corrupted)

- Rebuild produces an empty INDEX with just project metadata.
- Warn: `项目目录下没有任何文档,重建后 INDEX 为空`

### Case B: HTML file with corrupted metadata header

- Try to parse, extract whatever keys are present.
- Fill missing fields with sensible defaults (`status=active`, `version=1`, etc.).
- Flag in output: `文档 xxx.html 元数据不完整,已用默认值填充`

### Case C: Multiple files share the same doc_id

- Should never happen (doc_id has random suffix), but handle defensively.
- Keep the first one, warn about duplicates.
- Suggest user manually investigate.

### Case D: Compressed doc references missing source docs

- If compressed doc's archive section references doc_ids that no longer exist on disk: that's expected (they were archived).
- No action needed; the compressed doc itself preserves the content.

### Case E: Read-only filesystem

- Detect on backup or write attempt.
- Error: `无法写入 INDEX.yaml,请检查目录权限`

### Case F: identity.json missing

- Cannot resolve owner_name from id.
- Fallback to showing the raw id (`u-a3b2f1c9`).
- Warn: `无法解析用户名,请运行 /aim-identity 修复`

## Output Style

- Use Chinese for user-facing messages.
- Show full file paths.
- Use emoji consistently: ✅ 📋 📁 ⚠️ 📝 🔄
- For dry-run diffs, align columns for readability.
- Always show backup path so user can rollback manually if needed.

## Soft Sandbox Behavior

- `/aim-rebuild` is a **public command** — no sandbox restrictions.
- Does not modify HTML files, only INDEX.yaml.
- Safe to run for any user on the project (it's a cache rebuild, not a content change).

## Reference

- Companion commands: `/aim-verify`, `/aim-status`
- Concept: `reference/document-lifecycle.md`, `reference/rule-diff-verification.md`
