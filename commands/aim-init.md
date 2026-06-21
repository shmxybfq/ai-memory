---
name: aim-init
description: 初始化 ai-memory 项目记忆。每个项目运行一次,设置文档结构、INDEX.yaml,并将规则注入 CLAUDE.md。
---

# /aim-init — 初始化项目记忆

## 用途

为某个项目设置 ai-memory。创建文档结构、INDEX.yaml,并把规则注入 CLAUDE.md,这样 Claude Code 在未来的会话里就能感知到项目记忆。

**每个项目运行一次。** 在已初始化的项目上重新运行是安全的(会检测并跳过)。

## 用法

```
/aim-init [project-name]
```

- `project-name`(可选):项目的显示名称(例如 "视频项目")。如果省略,询问用户。

## 前置条件

- 已安装 Claude Code
- 集中式模式:你需要决定把所有项目文档放在哪个根目录下

## 流程

按顺序执行以下步骤。需要输入时停下来询问用户。

### 步骤 1:解析用户身份

检查全局身份是否存在:

```
读取 ~/.claude/ai-memory/identity.json
```

**如果存在**:直接使用,跳到步骤 2。

**如果不存在**:创建身份。

1. 尝试读取 git 全局用户名:
   ```
   执行:git config --global user.name
   ```
2. 如果 git 用户名存在,询问用户:
   ```
   检测到 git 用户名 [朱陶锋],是否使用?
   1. 使用
   2. 输入其他名字
   选择(1/2):
   ```
3. 如果 git 用户名缺失或用户选 2,询问:
   ```
   请输入你的名字(用于协作时标识作者):
   ```
4. 生成用户 ID:`u-` + 8 位随机字母数字(小写)。例如:`u-a3b2f1c9`。
5. 确定身份存储目录:
   - `~/.claude/ai-memory/` — 不存在则创建
6. 写入 `~/.claude/ai-memory/identity.json`:
   ```json
   {
     "id": "u-a3b2f1c9",
     "name": "朱陶锋",
     "created": "2026-06-21",
     "git_user": "zhu-taofeng"
   }
   ```
7. 向用户确认:`已创建身份: 朱陶锋 (u-a3b2f1c9)`

### 步骤 2:询问存储模式

询问用户:
```
请选择存储模式:
1. 集中式(推荐):所有项目文档统一放在一个根目录,一个 CLAUDE.md 管所有项目
2. 分散式:每个项目内嵌 .ai-memory/ 目录,文档随代码走
选择(1/2,默认 1):
```

- 默认:1(集中式)
- 保存为 `MODE`(central / distributed)

### 步骤 3:解析文档根目录

**集中式模式**:
询问用户根目录路径:
```
请输入文档根目录路径(默认: ~/Desktop/persistent-document/):
```
- 如果为空,使用 `~/Desktop/persistent-document/`
- 将 `~` 展开为 home 目录
- 保存为 `ROOT_PATH`
- 如果根目录不存在,询问:`路径不存在,是否创建? (Y/n)`。默认 Y。

**分散式模式**:
- `ROOT_PATH` = 当前工作目录(cwd)
- 无需询问

### 步骤 4:解析项目名称与子目录名

**项目显示名称**:
- 如果命令参数提供了(如 `/aim-init 视频项目`),直接使用
- 否则询问:
  ```
  请输入项目名(用于显示,如"视频项目"):
  ```
- 保存为 `PROJECT_NAME`

**子目录名**(文件系统名):

询问用户:
```
请输入项目子目录名(用于文件系统,建议英文/拼音,如"bauto-video"):
```
- 保存为 `SUBDIR_NAME`
- 校验:不能有空格,除 `-` 和 `_` 外不能有特殊字符
- 不合法则重新询问

**集中式模式**:项目路径 = `ROOT_PATH / SUBDIR_NAME`
**分散式模式**:项目路径 = `ROOT_PATH / .ai-memory`

### 步骤 5:检查项目是否已存在

读取 `<project_path>/INDEX.yaml`。

**如果存在**:
```
项目 [视频项目] 已初始化。
INDEX.yaml 位置: <project_path>/INDEX.yaml
如需重新初始化,请先 /aim-archive 或手动删除 INDEX.yaml。
操作终止。
```
停止。

**如果不存在**:继续。

### 步骤 6:创建项目结构

**集中式模式**:
```
执行:mkdir -p <ROOT_PATH>/<SUBDIR_NAME>
```

**分散式模式**:
```
执行:mkdir -p <ROOT_PATH>/.ai-memory
```

### 步骤 7:生成 INDEX.yaml

读取模板:`templates/INDEX.yaml.tpl`

替换占位符:
- `{{PROJECT_NAME}}` → PROJECT_NAME
- `{{MODE}}` → MODE(central / distributed)
- `{{ROOT_PATH}}` → 项目绝对路径
- `{{CREATED_DATE}}` → 今天(YYYY-MM-DD)
- `{{UPDATED_DATE}}` → 今天
- `{{USER_ID}}` → identity.id
- `{{USER_NAME}}` → identity.name

写入:`<project_path>/INDEX.yaml`

### 步骤 8:注入 CLAUDE.md 规则

**确定 CLAUDE.md 路径**:
- 集中式模式:`<ROOT_PATH>/CLAUDE.md`
- 分散式模式:`<ROOT_PATH>/CLAUDE.md`

**检查 ai-memory 规则是否已注入**:
```
读取 CLAUDE.md(如果存在)
搜索:<!-- ai-memory rules start
```

**如果找到**:
```
CLAUDE.md 已包含 ai-memory 规则,跳过注入。
```
跳过注入。

**如果未找到**:追加规则。

1. 读取模板:`templates/claude-md-rules.md.tpl`
2. 替换占位符:
   - `{{GITHUB_USER}}` → `shmxybfq`
   - `{{MODE}}` → MODE(central / distributed)
3. 处理条件块 `{{#CENTRAL}} ... {{/CENTRAL}}`:
   - **集中式模式**:把 `{{#CENTRAL}}` 和 `{{/CENTRAL}}` 标记行本身替换为空(保留中间内容)。然后在该块内,把 `{{PROJECT_MAPPING}}` 替换为该根目录下所有项目列表:
     ```
     - <SUBDIR_NAME> → <PROJECT_NAME>
     ```
     如果根目录下还有其他项目(扫描同级目录中的 INDEX.yaml),也一并纳入。
   - **分散式模式**:删除从 `{{#CENTRAL}}` 到 `{{/CENTRAL}}` 的整块(包含这两行)。
4. 如果 CLAUDE.md 不存在,以这些规则作为唯一内容创建。
5. 如果 CLAUDE.md 存在:
   - 如果是普通文件:在末尾以 `\n\n` 分隔追加规则。
   - 如果是**符号链接**:解析符号链接目标,写入目标文件(不要破坏链接)。提示用户:`CLAUDE.md 是符号链接,已写入目标 [xxx],链接保持不变`。

### 步骤 9:Git 初始化(可选)

**询问用户**:
```
是否将此项目纳入 Git 版本管理? (Y/n)
```

- 分散式模式默认 Y(项目代码通常已在 git 中)
- 集中式模式默认 n(个人文档集,可能纳入也可能不纳入)

**如果 Y**:
- 集中式模式:`cd <ROOT_PATH> && git init`(如果尚未在 git 中)
- 分散式模式:通常已在 git 中,只需把 `.ai-memory/` 加入追踪

提交:
```
git add <project files> <CLAUDE.md>
git commit -m "[aim-init] <PROJECT_NAME> - 初始化项目记忆 (<USER_NAME>)"
```

### 步骤 10:输出结果

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
   - /Users/zhutaofeng/Desktop/persistent-document/CLAUDE.md(已追加规则)

📝 下一步
   1. /aim-add 添加你的第一份文档
   2. /aim-status 查看项目状态
   3. 攒 3-5 篇后用 /aim-compress 压缩归档

💡 提示
   新会话开始时,Claude 会自动读 INDEX.yaml 和压缩文档,
   不需要重新探索项目。
```

## 边界情况

### 情况 A:身份文件存在但已损坏
- 尝试解析 JSON
- 如果失败:提示用户,请求覆盖授权
- 将旧文件备份为 `identity.json.bak.<timestamp>`

### 情况 B:根目录路径需要 sudo(macOS 用户目录下基本不会)
- 跳过并报错:`无法创建目录 [xxx],请检查权限`

### 情况 C:项目子目录名与已存在的目录冲突(非 ai-memory 产生)
- 检查 `<path>/INDEX.yaml` 是否存在(已在步骤 5 处理)
- 如果目录存在但没有 INDEX.yaml:询问 `目录已存在但不是 ai-memory 项目,是否在此目录初始化? (Y/n)`

### 情况 D:CLAUDE.md 是只读
- 写入时检测
- 报错:`无法写入 CLAUDE.md,请检查文件权限`

### 情况 E:用户中途取消(选择"取消"或退出)
- 清理已创建的半成品文件
- 如 CLAUDE.md 被部分修改则还原

## 输出风格

- 用户可见信息默认用中文
- 代码/文件内容用英文
- 输出中使用 emoji(✅ ❌ ⚠️ 📋 📁 📝 💡)以提升可读性
- 显示完整文件路径(用户在终端中可点击)

## 参考

- 模板:`templates/INDEX.yaml.tpl`
- 模板:`templates/claude-md-rules.md.tpl`
- 概念文档:`reference/central-vs-distributed.md`
