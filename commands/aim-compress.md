---
name: aim-compress
description: Merge active documents into a single compressed HTML file with dual-zone (active + archive). MVP version: single-pass LLM merge with rule-based verification. Use when 3+ active docs accumulated.
---

# /aim-compress — Compress Active Documents (MVP)

## Purpose

Consolidate multiple active documents into **one** compressed HTML file, organized into two zones:
- **当前有效区**: Current valid knowledge, AI reads this by default in new sessions.
- **历史归档区**: Deprecated/superseded content, kept for traceability but soft-deleted from active reading.

After compression, the original active docs are moved to `snapshots/YYYY-MM-DD/` (recoverable), and INDEX.yaml `active` list is cleared.

**This is the MVP version**: single-pass LLM merge with rule-based verification on hard info (versions, file paths, commands, config values). The full three-stage pipeline (analyze → merge → verify with retry) is deferred to v0.2.

Use this command when:
- 3+ active docs accumulated (`/aim-status` will suggest this)
- About to start a major phase shift (e.g., architecture migration)
- Tokens in active list exceed comfortable reading budget (~30k)

## Usage

```
/aim-compress [--dry-run] [--include <doc_id1,doc_id2,...>] [--exclude <doc_id1,...>]
```

- `--dry-run`: Show what would be compressed and the proposed outline, without writing.
- `--include`: Compress only the listed doc_ids (default: all active).
- `--exclude`: Compress all active except the listed ones.

No argument: compress all active docs.

## Prerequisites

- Project initialized.
- At least 1 active document (warn if < 3, allow override).
- INDEX.yaml consistent (recommend `/aim-verify` first if unsure).
- User has write access to project root.

## Flow

### Step 1: Resolve Current Project

Same logic as `/aim-add` Step 1.

### Step 2: Resolve User Identity

Read `~/.claude/ai-memory/identity.json`. Required — compression tags the operator.

### Step 3: Select Source Documents

Default: all entries in `INDEX.yaml` `active`.

Apply `--include` / `--exclude` filters if provided.

Validate:
- All selected doc_ids exist in INDEX.
- All corresponding files exist on disk.
- At least 1 doc remains after filtering.

If < 3 docs selected: warn `仅 N 篇文档,通常建议积累到 3+ 再压缩。是否继续? (Y/n)`.

### Step 4: Read All Source Documents

For each selected doc:

1. Read full HTML content.
2. Extract body (strip `<head>`, `<style>`).
3. Note metadata: title, owner, created, source, tags.
4. Append to `SOURCE_DOCS` list with positional index.

### Step 5: Check Existing Compressed Doc

If `INDEX.yaml` `compressed` already has an entry:

1. Read the existing compressed file.
2. Note its current active zone and archive zone.
3. Set `MERGE_MODE = incremental` (merge new docs into existing compressed doc).
4. Inform user: `检测到已有压缩文档,本次将合并新增内容并归档旧版本`

Otherwise: `MERGE_MODE = fresh`.

### Step 6: Generate Compressed Content (LLM Pass)

This is the core step. Use the LLM (yourself) to consolidate.

**Input to LLM**:
- All source docs (full text).
- For incremental mode: existing compressed doc content.
- Project name, current date, operator identity.

**Instructions to LLM** (the prompt you should follow internally):

```
你是项目记忆压缩助手。请将以下文档合并为单一 HTML 文档。

要求:
1. 输出严格遵循 templates/compressed-template.html.tpl 的结构。
2. 内容分为「当前有效区」(7 个固定章节) 和「历史归档区」。

固定章节(当前有效区):
  一、项目概述
  二、架构演进
  三、当前架构
  四、核心组件
  五、技术选型
  六、关键决策记录
  七、已知限制与待办

3. 合并规则:
   - 同主题内容合并,去除重复。
   - 互相矛盾的内容:较新的覆盖较旧的,旧版本移入归档区(deprecated)。
   - 明确标注来源(每段内容末尾标 [来源:文档标题 @ 作者])。
   - 保留所有硬信息:版本号、文件路径、命令、配置值、API 名称等(原样保留,不重写)。

4. 增量模式(如适用):
   - 已有压缩文档的「当前有效区」作为基线。
   - 新文档内容融入相应章节。
   - 被新内容替代的旧段落移入「历史归档区」,标 [deprecated:被 <新文档> 替代 @ 日期]。

5. 禁止:
   - 编造未在源文档中出现的信息。
   - 删除任何具体的版本号、路径、命令、配置值。
   - 改变技术决策的语义(可以浓缩表述,但不能反转结论)。

6. 在文档末尾输出「合并日志」表格:列出每篇源文档的处理方式(融入/归档/部分保留)。

源文档如下:
[粘贴所有源文档全文]

已有压缩文档(增量模式时):
[粘贴现有压缩文档,无则省略]

项目元信息:
- 项目名: {{PROJECT_NAME}}
- 操作日期: {{TODAY}}
- 操作者: {{USER_NAME}} ({{USER_ID}})
```

**Output**: a complete HTML document following the compressed template.

### Step 7: Rule-Based Verification

After LLM generates the compressed doc, verify hard info is preserved.

For each source doc, extract via regex:
- Version-like strings: `\d+\.\d+(\.\d+)?` (e.g., `1.2.3`, `0.1`)
- File paths: `[\w\-/.]+\.\w+` (e.g., `src/index.ts`)
- Commands: `` `[^`]+` `` (backtick-quoted)
- Config keys: `[A-Z_][A-Z0-9_]{2,}=` (e.g., `DATABASE_URL=`)
- API names: `\b(GET|POST|PUT|DELETE)\b /[\w-/]+`

Check that each extracted item appears in the compressed output.

**If any missing**:
1. Flag the missing items.
2. Either:
   - Re-prompt the LLM with explicit instructions to include them (one retry).
   - Manually append a `<!-- preserved-hard-info -->` block at the end of the compressed doc with the missing items verbatim.
3. Log the verification result in the merge log.

**MVP note**: do at most one retry. If still missing after retry, preserve verbatim in appendix block. Don't loop indefinitely.

### Step 8: Determine Output File

Filename: `compressed-YYYYMMDD.html` (e.g., `compressed-20260621.html`).

If file exists (same-day re-compress): append `-N` suffix (`compressed-20260621-2.html`).

Full path:
- Central mode: `<root>/<subdir>/compressed-YYYYMMDD.html`
- Distributed mode: `<project>/.ai-memory/compressed-YYYYMMDD.html`

### Step 9: Write Compressed Doc

Write the HTML to the output path.

Verify write succeeded (read back, check size > 1KB).

### Step 10: Archive Source Documents

For each source doc:

1. Create snapshot dir: `<root>/snapshots/YYYY-MM-DD/` (mkdir -p).
2. Move (not copy) the source HTML from active location to snapshot dir.
3. Record in `INDEX.yaml` `snapshots` list:
   ```yaml
   - date: "2026-06-21"
     reason: "compressed"
     files:
       - "2026-06-21-auth.html"
       - "2026-06-20-routing.html"
     compressed_into: "compressed-20260621.html"
   ```

Never delete source files — always move to snapshots.

### Step 11: Update INDEX.yaml

1. Clear `active` list (all entries moved to snapshots).
2. Update `compressed` list:
   ```yaml
   compressed:
     - doc_id: "aim-20260621-<random>"
       file: "compressed-20260621.html"
       title: "项目压缩文档-视频项目"
       owner: "__project__"
       created: "2026-06-21"
       created_by: "u-a3b2f1c9"
       created_by_name: "朱陶锋"
       version: 1
       tokens: 12500
       sources_count: 6
       contributors:
         - { user: "u-a3b2f1c9", name: "朱陶锋", last: "2026-06-21" }
   ```
3. Update top-level `updated` to today.
4. Update `snapshots` list per Step 10.

For incremental mode: instead of clearing, replace the existing `compressed[0]` with the new merged version (increment `version` field).

### Step 12: Git Commit (Optional)

If project is in git:

```
git add compressed-YYYYMMDD.html snapshots/YYYY-MM-DD/ INDEX.yaml
git rm <old active files>  # explicitly remove from index since they moved
git commit -m "[aim-compress] <PROJECT_NAME> - 2026-06-21 压缩归档 (合并 N 篇)"
```

If not in git: skip, note `未纳入 Git,压缩文档已生成但未版本管理`.

### Step 13: Output Result

```
✅ 压缩完成

📋 压缩信息
   合并文档: 6 篇 → 1 篇压缩文档
   压缩前: 8,400 tokens
   压缩后: 12,500 tokens (净增 4,100,但 7 章节结构化)
   操作者: 朱陶锋 (u-a3b2f1c9)
   模式: fresh / 增量合并

📁 生成文件
   压缩文档: /Users/.../compressed-20260621.html
   快照目录: /Users/.../snapshots/2026-06-21/ (6 篇源文档)

🔍 校验结果
   ✅ 硬信息保留: 24/24 项
   ✅ 来源标注: 6/6 篇
   ⚠️ 重复内容: 已合并 12 段

📊 项目状态(压缩后)
   活跃: 0 篇
   压缩: 1 篇 (12,500 tokens)
   快照: 3 个目录 (累计 20 篇归档)

📝 下一步
   - /aim-add        在新基线上继续记录
   - /aim-status     查看完整状态
   - /aim-expand     从快照恢复细节(如需要)
```

## Edge Cases

### Case A: Only 1-2 active docs

- Warn but allow override.
- Output: `仅 N 篇,压缩价值有限。是否仍要继续? (Y/n)`.

### Case B: Active docs have conflicting versions of same fact

- LLM should keep newer, archive older with `[deprecated]` tag.
- If dates are equal/unknown: keep both in active zone with explicit "存在两种说法" note.

### Case C: Source doc is huge (>5000 tokens individually)

- Warn before compression.
- Suggest: `文档 X 较大,建议先 /aim-edit 拆分,再压缩。是否仍要纳入? (Y/n)`.

### Case D: Compression would exceed sane limit (>30k tokens compressed)

- Warn: `压缩后预计 N tokens,可能影响新会话读取效率。建议先拆分为多个项目或归档部分内容`。
- Allow override.

### Case E: Verification fails (hard info missing after retry)

- Do NOT discard the compression.
- Append missing items as a `<!-- preserved-hard-info -->` block at end of compressed doc.
- Add 🟠 warning to output: `N 项硬信息未融入正文,已在附录保留`.

### Case F: User runs /aim-compress on an empty active list

- Stop: `活跃文档为空,无需压缩`.

### Case G: Snapshot directory for today already exists (re-compress same day)

- Append to existing snapshot dir (don't overwrite).
- Filename gets `-N` suffix to avoid collision.

### Case H: Power failure / crash mid-compression

- Worst case: compressed doc written but INDEX not updated, or sources moved but INDEX not updated.
- Recovery: `/aim-verify` will flag the inconsistency; `/aim-rebuild` will reconcile from filesystem.

## Output Style

- Use Chinese for user-facing messages.
- Show before/after token counts.
- Always show snapshot path so user knows where originals went.
- Emoji: ✅ 📋 📁 🔍 📊 📝 ⚠️ 🗜️
- For dry-run, show proposed outline (section titles + which docs land where) without writing.

## Soft Sandbox Behavior

- `/aim-compress` is **special**: it modifies the shared compressed doc (`owner=__project__`).
- For single-user projects: no confirmation needed beyond normal flow.
- For multi-user projects: if any source doc has a different owner than current user, prompt:
  ```
  本次压缩包含其他用户的文档:
    - 张三 (u-b1c2d3e4): 2 篇
    - 李四 (u-c3d4e5f6): 1 篇
  跨用户压缩公共文档,确认? (Y/n)
  ```
- Once confirmed, no caching (per project rule).

## MVP Limitations (vs full v0.2)

- ❌ No three-stage pipeline (analyze/merge/verify as separate LLM calls with structured intermediate output).
- ❌ No iterative refinement loop (just one retry on hard info miss).
- ❌ No section-level quality scoring.
- ❌ No automatic identification of "should split into multiple compressions".

What MVP does have:
- ✅ Dual-zone output (active + archive).
- ✅ Source attribution.
- ✅ Rule-based hard info verification.
- ✅ Snapshot preservation of originals.
- ✅ Incremental merge with existing compressed doc.

## Reference

- Template: `templates/compressed-template.html.tpl`
- Concept: `reference/three-stage-pipeline.md` (full design, deferred)
- Concept: `reference/rule-diff-verification.md`
- Companion commands: `/aim-status`, `/aim-expand`, `/aim-rebuild`
