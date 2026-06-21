---
name: aim-init
description: Initialize ai-memory project memory. Run once per project to set up document structure, INDEX.yaml, and CLAUDE.md rule injection.
---

# /aim-init — Initialize Project Memory

## Purpose

Set up ai-memory for a project. Creates the document structure, INDEX.yaml, and injects rules into CLAUDE.md so Claude Code knows about the project memory in future sessions.

**Run once per project.** Re-running on an initialized project is safe (detects and skips).

## Usage

```
/aim-init [project-name]
```

- `project-name` (optional): Display name for the project (e.g., "视频项目"). If omitted, ask the user.

## Prerequisites

- Claude Code installed
- For central mode: know where you want to store all project docs (one root directory)

## Flow

Execute these steps in order. Stop and ask the user when input is needed.

### Step 1: Resolve User Identity

Check if global identity exists:

```
Read ~/.claude/ai-memory/identity.json
```

**If exists**: use it, skip to Step 2.

**If not exists**: create identity.

1. Try to read git global username:
   ```
   Run: git config --global user.name
   ```
2. If git name exists, ask user:
   ```
   检测到 git 用户名 [朱陶锋],是否使用?
   1. 使用
   2. 输入其他名字
   选择(1/2):
   ```
3. If git name missing or user chose 2, ask:
   ```
   请输入你的名字(用于协作时标识作者):
   ```
4. Generate user ID: `u-` + 8 random alphanumeric chars (lowercase). Example: `u-a3b2f1c9`.
5. Determine storage directory for identity:
   - `~/.claude/ai-memory/` — create if not exists
6. Write `~/.claude/ai-memory/identity.json`:
   ```json
   {
     "id": "u-a3b2f1c9",
     "name": "朱陶锋",
     "created": "2026-06-21",
     "git_user": "zhu-taofeng"
   }
   ```
7. Confirm to user: `已创建身份: 朱陶锋 (u-a3b2f1c9)`

### Step 2: Ask Storage Mode

Ask user:
```
请选择存储模式:
1. 集中式(推荐):所有项目文档统一放在一个根目录,一个 CLAUDE.md 管所有项目
2. 分散式:每个项目内嵌 .ai-memory/ 目录,文档随代码走
选择(1/2,默认 1):
```

- Default: 1 (central)
- Save choice as `MODE` (central / distributed)

### Step 3: Resolve Document Root

**Central mode**:
Ask user for root path:
```
请输入文档根目录路径(默认: ~/Desktop/persistent-document/):
```
- If empty, use `~/Desktop/persistent-document/`
- Expand `~` to home directory
- Save as `ROOT_PATH`
- If root doesn't exist, ask: `路径不存在,是否创建? (Y/n)`. Default Y.

**Distributed mode**:
- `ROOT_PATH` = current working directory (cwd)
- No need to ask

### Step 4: Resolve Project Name and Subdir Name

**Project display name**:
- If command argument provided (e.g., `/aim-init 视频项目`), use it
- Otherwise ask:
  ```
  请输入项目名(用于显示,如"视频项目"):
  ```
- Save as `PROJECT_NAME`

**Subdirectory name** (file system name):

Ask user:
```
请输入项目子目录名(用于文件系统,建议英文/拼音,如"bauto-video"):
```
- Save as `SUBDIR_NAME`
- Validate: no spaces, no special chars except `-` and `_`
- If invalid, ask again

**Central mode**: project path = `ROOT_PATH / SUBDIR_NAME`
**Distributed mode**: project path = `ROOT_PATH / .ai-memory`

### Step 5: Check for Existing Project

Read `<project_path>/INDEX.yaml`.

**If exists**: 
```
项目 [视频项目] 已初始化。
INDEX.yaml 位置: <project_path>/INDEX.yaml
如需重新初始化,请先 /aim-archive 或手动删除 INDEX.yaml。
操作终止。
```
Stop.

**If not exists**: continue.

### Step 6: Create Project Structure

**Central mode**:
```
Run: mkdir -p <ROOT_PATH>/<SUBDIR_NAME>
```

**Distributed mode**:
```
Run: mkdir -p <ROOT_PATH>/.ai-memory
```

### Step 7: Generate INDEX.yaml

Read template: `templates/INDEX.yaml.tpl`

Replace placeholders:
- `{{PROJECT_NAME}}` → PROJECT_NAME
- `{{MODE}}` → MODE (central / distributed)
- `{{ROOT_PATH}}` → absolute project path
- `{{CREATED_DATE}}` → today (YYYY-MM-DD)
- `{{UPDATED_DATE}}` → today
- `{{USER_ID}}` → identity.id
- `{{USER_NAME}}` → identity.name

Write to: `<project_path>/INDEX.yaml`

### Step 8: Inject CLAUDE.md Rules

**Determine CLAUDE.md path**:
- Central mode: `<ROOT_PATH>/CLAUDE.md`
- Distributed mode: `<ROOT_PATH>/CLAUDE.md`

**Check if ai-memory rules already injected**:
```
Read CLAUDE.md (if exists)
Search for: <!-- ai-memory rules start
```

**If found**:
```
CLAUDE.md 已包含 ai-memory 规则,跳过注入。
```
Skip injection.

**If not found**: append rules.

1. Read template: `templates/claude-md-rules.md.tpl`
2. Replace placeholders:
   - `{{GITHUB_USER}}` → `shmxybfq`
   - `{{MODE}}` → MODE
   - For central mode, include project mapping:
     ```
     {{#CENTRAL}}...{{PROJECT_MAPPING}}...{{/CENTRAL}}
     ```
   - Build `PROJECT_MAPPING` as a list under the root:
     ```
     - <SUBDIR_NAME> → <PROJECT_NAME>
     ```
     If other projects already exist in root (scan INDEX.yaml in sibling dirs), include them too.
3. If CLAUDE.md doesn't exist, create it with the rules as the only content.
4. If CLAUDE.md exists, append rules to the end with `\n\n` separator.

### Step 9: Git Initialization (Optional)

**Ask user**:
```
是否将此项目纳入 Git 版本管理? (Y/n)
```

- Default Y for distributed mode (project codebase already in git usually)
- Default n for central mode (personal doc collection, may or may not be in git)

**If Y**:
- Central mode: `cd <ROOT_PATH> && git init` (if not already in git)
- Distributed mode: usually already in git, just add `.ai-memory/` to tracking

Commit:
```
git add <project files> <CLAUDE.md>
git commit -m "[aim-init] <PROJECT_NAME> - 初始化项目记忆 (<USER_NAME>)"
```

### Step 10: Output Result

```
✅ ai-memory 初始化完成

📋 项目信息
   项目名: 视频项目
   模式: 集中式
   位置: /Users/zhutaofeng/Desktop/persistent-document/bauto-video

👤 用户身份
   朱陶锋 (u-a3b2f1c9)

📁 创建的文件
   - /Users/zhutaofeng/Desktop/persistent-document/bauto-video/INDEX.yaml
   - /Users/zhutaofeng/Desktop/persistent-document/CLAUDE.md (已追加规则)

📝 下一步
   1. /aim-add 添加你的第一份文档
   2. /aim-status 查看项目状态
   3. 攒 3-5 篇后用 /aim-compress 压缩归档

💡 提示
   新会话开始时,Claude 会自动读 INDEX.yaml 和压缩文档,
   不需要重新探索项目。
```

## Edge Cases

### Case A: Identity file exists but is corrupted
- Try to parse JSON
- If fails: warn user, ask permission to overwrite
- Backup old file to `identity.json.bak.<timestamp>`

### Case B: Root path requires sudo (unlikely on macOS user dirs)
- Skip with error: `无法创建目录 [xxx],请检查权限`

### Case C: Project subdir name collides with existing dir (not from ai-memory)
- Check if `<path>/INDEX.yaml` exists (already handled in Step 5)
- If dir exists but no INDEX.yaml: ask `目录已存在但不是 ai-memory 项目,是否在此目录初始化? (Y/n)`

### Case D: CLAUDE.md is read-only
- Detect on write attempt
- Error: `无法写入 CLAUDE.md,请检查文件权限`

### Case E: User cancels mid-flow (chooses "取消" or quits)
- Clean up any partial files created
- Restore CLAUDE.md if partially modified

## Output Style

- Use Chinese for user-facing messages (default)
- Use English for code/file content
- Use ✅ ❌ ⚠️ 📋 📁 📝 💡 emojis in output (improves readability)
- Show full file paths (user can click in terminal)

## Reference

- Template: `templates/INDEX.yaml.tpl`
- Template: `templates/claude-md-rules.md.tpl`
- Concept doc: `reference/central-vs-distributed.md`
