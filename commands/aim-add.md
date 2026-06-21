---
name: aim-add
description: Add a new document to the project memory. Always creates a new file (never modifies existing). Use for recording knowledge, decisions, debugging notes, or summaries.
---

# /aim-add — Add New Document

## Purpose

Create a new HTML document in the project's memory directory, with proper metadata embedding and INDEX.yaml update. **Always creates a new file** — use `/aim-append` to extend or `/aim-edit` to modify existing docs.

## Usage

```
/aim-add [natural language content or description]
```

- If content is provided as argument, use it directly.
- If no argument, ask user to paste content or describe what to record.

## Prerequisites

- Project must be initialized (`/aim-init` done). Detect by:
  - Central mode: `<root>/<subdir>/INDEX.yaml` exists
  - Distributed mode: `<cwd>/.ai-memory/INDEX.yaml` exists
- If not initialized: stop with message: `项目未初始化,请先运行 /aim-init`

## Flow

### Step 1: Resolve Current Project

1. Check current working directory.
2. Try to find project:
   - **Distributed mode**: look for `<cwd>/.ai-memory/INDEX.yaml`
   - **Central mode**: scan known roots (`~/Desktop/persistent-document/` and other roots recorded in `~/.claude/ai-memory/projects.json`) for subdirs containing INDEX.yaml matching cwd context.
3. If multiple projects found, ask user which one.
4. If no project found: error and stop.

Read INDEX.yaml, save as `INDEX`.

### Step 2: Resolve User Identity

1. Read `~/.claude/ai-memory/identity.json`.
2. If missing: error `用户身份未初始化,请重新运行 /aim-init`.
3. Save as `USER`.

### Step 3: Collect Document Content

**If command argument provided**: use it as `RAW_CONTENT`.

**If not provided**, prompt user:
```
请输入要记录的内容(可以是自然语言描述、技术决策、踩坑记录等):
[等待用户输入,可能多行]
```

Save as `RAW_CONTENT`.

### Step 4: Determine Document Metadata

#### 4.1 Title

Look at RAW_CONTENT. If it starts with a clear topic, propose a title.

Ask user:
```
建议标题: [基于内容生成的标题]
请确认或修改(回车确认):
```

Save as `TITLE`.

#### 4.2 Source

Ask user (with default):
```
文档来源:
1. 对话(对话沉淀、决策记录)
2. 踩坑(bug、问题排查)
3. 外部(资料、链接整理)
4. 决策(技术选型、方案对比)
选择(1-4,默认 1):
```

Save as `SOURCE` (对话/踩坑/外部/决策).

#### 4.3 Tags

Ask user (optional):
```
标签(逗号分隔,可选,如 auth,security,api):
```

If empty, use `[]`. Otherwise parse to list. Save as `TAGS`.

#### 4.4 Filename

Generate from TITLE:
- Replace spaces with `-`
- Remove special chars except `-`, `_`, `.`
- Append date prefix `YYYY-MM-DD-`
- Example: `2026-06-21-auth-module-design.html`

If filename conflicts with existing file in project dir:
```
文件 [xxx.html] 已存在,是否:
1. 自动加后缀(auth-module-design-2.html)
2. 重新输入文件名
选择(1/2):
```

Save as `FILENAME`.

#### 4.5 Doc ID

Generate: `aim-` + `YYYYMMDD` + `-` + 6 random alphanumeric chars.
Example: `aim-20260621-a3b2f1`.

Save as `DOC_ID`.

### Step 5: Generate HTML Content

Use Claude to structure RAW_CONTENT into well-formatted HTML.

**Structure rules**:
- Use the HTML template: `templates/doc-template.html.tpl`
- Apply section structure: title, metadata block, content sections, footer
- Convert markdown-like content (lists, code blocks, tables) to proper HTML
- Apply consistent styling (the template has built-in CSS)

**Render template with**:
- `{{DOC_ID}}` → DOC_ID
- `{{TITLE}}` → TITLE
- `{{TAGS}}` → TAGS joined as string
- `{{CREATED}}` → today (YYYY-MM-DD)
- `{{CREATED_BY}}` → USER.id
- `{{OWNER}}` → USER.id
- `{{OWNER_NAME}}` → USER.name
- `{{SOURCE}}` → SOURCE
- `{{CONTENT}}` → structured HTML from RAW_CONTENT

**Metadata header in HTML comment** (already in template):
```html
<!-- aim:doc_id=aim-20260621-a3b2f1 title=认证模块设计 tags=auth,security created=2026-06-21 created_by=u-a3b2f1c9 owner=u-a3b2f1c9 status=active source=对话 -->
```

### Step 6: Write File

Determine write path:
- Central mode: `<ROOT>/<SUBDIR>/<FILENAME>`
- Distributed mode: `<ROOT>/.ai-memory/<FILENAME>`

Write HTML content to file.

### Step 7: Update INDEX.yaml

Append to `active` list:
```yaml
- doc_id: "aim-20260621-a3b2f1"
  title: "认证模块设计"
  file: "2026-06-21-auth-module-design.html"
  owner: "u-a3b2f1c9"
  owner_name: "朱陶锋"
  created: "2026-06-21"
  created_by: "u-a3b2f1c9"
  updated: "2026-06-21"
  last_modified_by: "u-a3b2f1c9"
  version: 1
  status: "active"
  source: "对话"
  tags: [auth, security]
  permission: "private"
  tokens: <estimated>
  contributors:
    - { user: "u-a3b2f1c9", name: "朱陶锋", last: "2026-06-21" }
```

Update INDEX.yaml top-level `updated` field to today.

### Step 8: Token Estimation

Estimate tokens for the new doc (rough: Chinese ~1 char = 1 token, English ~4 chars = 1 token, HTML tags ~50% overhead).

Save to the active entry's `tokens` field.

### Step 9: Git Commit (Optional)

Check if project is in git repo.

**If in git**:
- `git add <FILENAME> INDEX.yaml`
- `git commit -m "[aim-add] <PROJECT_NAME> - 新建 <FILENAME> (doc:<DOC_ID>)"`

**If not in git**: skip, just inform user `未纳入 Git,文档已保存但未版本管理`.

### Step 10: Output Result

```
✅ 文档已添加

📋 文档信息
   标题: 认证模块设计
   doc_id: aim-20260621-a3b2f1
   标签: auth, security
   来源: 对话

📁 文件位置
   /Users/zhutaofeng/Desktop/persistent-document/bauto-video/2026-06-21-auth-module-design.html

📊 项目状态
   活跃文档: 6 篇 (累计 8,400 tokens)
   压缩文档: 1 篇 (12,500 tokens)
   💡 提示: 活跃文档已 6 篇,建议运行 /aim-compress 整理

📝 下一步
   - 继续添加: /aim-add
   - 查看状态: /aim-status
   - 压缩归档: /aim-compress
```

**Compress suggestion threshold**:
- 3+ active docs → gentle hint
- 5+ active docs → strong recommendation
- 8+ active docs → warning (memory bloat risk)

## Edge Cases

### Case A: Project not initialized
- Detect by missing INDEX.yaml
- Stop: `项目未初始化,请先运行 /aim-init`

### Case B: Identity missing or invalid
- Stop: `用户身份未初始化,请重新运行 /aim-init 或 /aim-identity`

### Case C: Filename collision (same title used before)
- Detect before write
- Ask user: rename or cancel

### Case D: Content is empty
- If RAW_CONTENT is empty/whitespace: `内容为空,操作取消`

### Case E: Content too large
- If estimated > 5000 tokens for a single doc:
  - Warn user: `内容较长(约 X tokens),建议拆分为多篇文档。是否继续? (Y/n)`

### Case F: INDEX.yaml is corrupted
- Try to parse YAML
- If fails: `INDEX.yaml 损坏,请运行 /aim-rebuild 修复后重试`

## Soft Sandbox Behavior

- `/aim-add` always creates files owned by current user (`owner = USER.id`).
- No cross-user confirmation needed (new file is always own).
- Document `permission` defaults to `private` (only owner can modify without confirmation).

## Output Style

- Use Chinese for user-facing messages
- Show full file paths
- Use emojis (✅ 📋 📁 📊 💡 📝) consistently
- Keep output concise but informative

## Reference

- Template: `templates/doc-template.html.tpl`
- Concept: `reference/document-lifecycle.md`
- Companion commands: `/aim-append`, `/aim-edit`
