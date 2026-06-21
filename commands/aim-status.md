---
name: aim-status
description: Show project memory status. Displays document counts, token estimates, Git drift warnings, and compression suggestions. Read-only, never modifies anything.
---

# /aim-status — Show Project Status

## Purpose

Display a snapshot of the current project's memory state: document inventory, token usage, contributor activity, Git drift, and health warnings. **Read-only** — never writes, never commits.

Use this command:
- After `/aim-init` to verify setup worked
- Periodically to monitor memory growth
- Before `/aim-compress` to decide if compression is needed
- When something feels off (missing docs, broken INDEX, sync issues)

## Usage

```
/aim-status
```

No arguments. Always operates on the current project (resolved from cwd).

## Prerequisites

- Project must be initialized. Detect by:
  - Distributed mode: `<cwd>/.ai-memory/INDEX.yaml` exists
  - Central mode: scan known roots for subdirs whose INDEX.yaml `root` matches cwd or cwd-relative path
- If not initialized: stop with `项目未初始化,请先运行 /aim-init`

## Flow

### Step 1: Resolve Current Project

Same resolution logic as `/aim-add` Step 1:

1. Check cwd.
2. Look for project:
   - **Distributed**: `<cwd>/.ai-memory/INDEX.yaml`
   - **Central**: scan `~/Desktop/persistent-document/` and roots in `~/.claude/ai-memory/projects.json` for subdirs with INDEX.yaml
3. If multiple match: ask user which one.
4. If none: error and stop.

Read INDEX.yaml. If parse fails, surface the error (see Edge Case A).

### Step 2: Resolve User Identity

Read `~/.claude/ai-memory/identity.json`.

- If exists: note current user (used for "your docs" grouping in output).
- If missing: continue but warn `用户身份未初始化,无法区分个人/他人文档`。

### Step 3: Inventory Active Documents

For each entry in `INDEX.yaml` `active`:

1. Verify file exists at `<root>/<file>`.
2. Read metadata header from file (`<!-- aim:doc_id=... -->`).
3. Cross-check INDEX.yaml fields vs file metadata:
   - `doc_id`, `title`, `owner`, `status`, `updated`, `version`
4. Count tokens (estimate from file size: `bytes / 3.5` as rough heuristic, refined by Chinese vs English ratio).
5. Bucket by:
   - Owner (own vs others)
   - Source type (对话/踩坑/外部/决策)
   - Tag
6. Track anomalies:
   - File missing on disk
   - INDEX has entry but file metadata mismatch
   - File exists but INDEX has no entry (orphan)

### Step 4: Inventory Compressed Document

For `INDEX.yaml` `compressed`:

1. Verify the compressed file exists.
2. Extract `version`, `created_by`, `contributors` from metadata header.
3. Count tokens.
4. Detect if a stale active doc still references an already-compressed source (rare but possible if rebuild ran out of order).

### Step 5: Inventory Snapshots

Scan `<root>/snapshots/` for dated subdirectories:

1. List all `snapshots/YYYY-MM-DD/` dirs.
2. For each, count HTML files inside.
3. Cross-reference with `INDEX.yaml` `snapshots` list.
4. Flag orphan snapshot dirs (on disk but not in INDEX).

### Step 6: Check Git Drift

Only if `<root>` (or distributed project root) is inside a git repo:

1. Run `git status --porcelain` — count modified/untracked files in the memory dir.
2. Run `git fetch --dry-run` (skip if offline) — detect if local is behind `origin/<branch>`.
3. Run `git log origin/<branch>..HEAD --oneline` — count commits ahead.
4. Run `git log HEAD..origin/<branch> --oneline` — count commits behind.

Cache nothing — fetch every time so the report reflects current remote state.

### Step 7: Compute Health Indicators

Calculate and format:

- **Compression urgency**:
  - active docs < 3: `良好`
  - 3-4: `温和提示,可考虑压缩`
  - 5-7: `强烈建议压缩`
  - 8+: `⚠️ 膨胀风险,建议立即压缩`
- **Token budget** (rough context window estimate):
  - target: keep active total under ~30,000 tokens for comfortable reading
  - warn if over 50,000
- **Largest single doc** (flag if > 5000 tokens)
- **Stale docs**: any `active` doc not updated in 30+ days (by `updated` field)
- **Cross-user pending**: any `contributors` entry from a non-owner user (signals collaboration)

### Step 8: Output Report

Format the report following the Output Style section below. Group sections with emoji headers. Keep concise — one screen height ideally.

If verbose mode requested (`/aim-status --detail`), also dump per-doc table.

## Edge Cases

### Case A: INDEX.yaml corrupted or unparseable

- Surface the parse error line.
- Suggest: `INDEX.yaml 解析失败,请运行 /aim-rebuild 修复`
- Do NOT proceed with inventory — would produce misleading counts.

### Case B: Project has zero active docs (freshly initialized)

- Display empty state:
  ```
  活跃文档: 0 篇
  还没有文档,运行 /aim-add 添加第一篇。
  ```

### Case C: File on disk but not in INDEX (orphan)

- List under "异常" section: `文件 xxx.html 存在但 INDEX.yaml 未记录`
- Suggest `/aim-rebuild` to reconcile.

### Case D: INDEX has entry but file missing

- List under "异常": `INDEX 记录 xxx.html 但文件不存在`
- Suggest restoring from git or removing the INDEX entry.

### Case E: Git repo exists but no remote configured

- Skip the drift check, note: `Git 已启用但无 remote,无法检查落后状态`

### Case F: Git fetch fails (offline / auth)

- Skip the remote check, note: `无法访问 remote (离线?),仅显示本地状态`

### Case G: Distributed mode but cwd is outside project

- Resolution logic in Step 1 should catch this.
- If somehow reached: error `当前目录不在任何 ai-memory 项目中`

### Case H: Mixed permissions (some docs private, some shared)

- In doc list, show `permission` badge next to each row.
- No special action, just visibility.

## Output Style

### Default Output

```
📊 ai-memory 项目状态

📋 项目
   名称: 视频项目
   模式: 集中式
   位置: /Users/zhutaofeng/Desktop/persistent-document/bauto-video
   初始化: 2026-06-15 (6 天前)

👤 当前用户
   朱陶锋 (u-a3b2f1c9)

📑 文档概览
   活跃: 6 篇 (8,400 tokens)
   压缩: 1 篇 (12,500 tokens,1 次合并)
   快照: 2 个目录 (累计 14 篇归档)

📈 活跃文档分布
   按来源:
     - 对话: 3 篇
     - 踩坑: 2 篇
     - 决策: 1 篇
   按作者:
     - 朱陶锋: 5 篇
     - 张三: 1 篇 (协作)

⚠️ 健康提示
   💡 活跃文档已 6 篇,建议运行 /aim-compress 整理
   ⚠️ 文档「认证模块重构」达 5,200 tokens,可考虑拆分
   📅 文档「早期 API 设计」30+ 天未更新

🔄 Git 状态
   分支: main
   未提交: 2 个文件 (INDEX.yaml, 2026-06-21-auth.html)
   与远程: 同步

📝 下一步建议
   - /aim-compress     压缩活跃文档
   - git add .         提交未保存变更
   - /aim-verify       完整一致性检查
```

### Verbose Output (`--detail`)

Adds a per-doc table after the summary:

```
📑 活跃文档明细
| doc_id            | 标题             | 作者   | tokens | 更新        |
|-------------------|------------------|--------|--------|-------------|
| aim-20260621-a3b2 | 认证模块设计     | 朱陶锋 | 1,200  | 2026-06-21  |
| aim-20260620-b1c2 | 路由优化踩坑     | 朱陶锋 | 800    | 2026-06-20  |
| aim-20260618-c3d4 | 第三方登录方案   | 张三   | 1,500  | 2026-06-20  |
| ...               |                  |        |        |             |
```

### Formatting Rules

- Use Chinese for all labels.
- Numbers with thousands separators (`8,400`).
- Dates as `YYYY-MM-DD`.
- Relative time in parens (`6 天前`, `2 小时前`).
- Path lines wrapped if > 80 chars (indent continuation with 3 spaces).
- Emojis used consistently: 📊 📋 👤 📑 📈 ⚠️ 🔄 📝 💡 🚫
- No trailing summary paragraph — keep it scan-friendly.

## Soft Sandbox Behavior

- `/aim-status` is a **public command** — no sandbox restrictions.
- Shows all documents regardless of owner.
- Contributor names shown in plain text (no PII beyond what's already in INDEX.yaml).

## Reference

- Companion commands: `/aim-add`, `/aim-compress`, `/aim-rebuild`, `/aim-verify`
- Concept: `reference/document-lifecycle.md`
- Token estimation: Chinese 1 char ≈ 1 token, English 4 chars ≈ 1 token, HTML overhead ~50%
