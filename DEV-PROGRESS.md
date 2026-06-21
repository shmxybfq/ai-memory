# ai-memory 开发进度文档

> 本文档用于跨会话/上下文压缩后恢复开发状态。Claude 新会话开始时优先读此文档。

**最后更新**: 2026-06-21 16:15
**当前阶段**: MVP 命令文档全部完成(任务 #1-#9 完成,剩 #10 真实测试 + 调优)

---

## 一、项目概述

**ai-memory** 是一个 Claude Code Skill 集合,为 Claude Code 用户提供跨会话的项目记忆能力。

- **GitHub**: https://github.com/shmxybfq/ai-memory
- **本地路径**: `~/Desktop/ai-memory/`
- **软链接**: `~/.claude/skills/ai-memory → ~/Desktop/ai-memory/`(开发即生效)
- **设计文档**: `~/Desktop/persistent-document/bauto-video/2026年06月12日压缩前快照/ai-memory开源项目设计方案讨论.html`(22 章)

---

## 二、用户信息

| 项 | 值 |
|---|---|
| GitHub 用户名 | `shmxybfq` |
| Git user.name | `朱陶锋` |
| Git user.email | `shmxybfq@163.com` |
| VPN 代理 | `all_proxy=socks5h://127.0.0.1:7890` |
| 操作系统 | macOS Darwin 24.6.0 |

---

## 三、关键约定(必须遵守)

### 3.1 用户偏好
- **所有交互界面文字使用中文**(feedback_chinese_ui.md 记忆)
- 不要过度设计,先做最小可行
- 边讨论边确认,重大决策走 AskUserQuestion
- 文档统一 HTML 格式(不用 Markdown)

### 3.2 设计决策(已锁定)
- **形态**: 纯 Claude Code Skill(不做 CLI、不做 MCP,留待后续升级)
- **默认模式**: 集中式(沿用 persistent-document 结构)
- **分散式**: 项目内嵌 `.ai-memory/`
- **文档格式**: HTML + 头部元数据注释(`<!-- aim:doc_id=... -->`)
- **INDEX.yaml**: 可重建缓存,不是真源
- **压缩文档**: 单文件双分区(当前有效 + 历史归档),软删除不真删
- **校验机制**: 规则 diff 优先于 LLM 自检(正则提取版本号、文件名、命令、配置值)
- **跨工具**: MVP 不做

### 3.3 协作设计(软沙盒)
- **用户身份**: 全局 `~/.claude/ai-memory/identity.json`(id 格式 `u-<8位随机>`)
- **身份获取**: 优先 git config user.name,其次询问
- **软沙盒**: 用户默认只能直接操作自己文档
- **跨沙盒**: 每次必问,无缓存,commit message 标 `[cross-user:from 张三]`
- **压缩文档归属**: `__project__`(不归个人)
- **doc_id 格式**: `aim-YYYYMMDD-<6位随机>`

### 3.4 分发决策(5 项已确认)
1. GitHub 仓库: **个人账号**(shmxybfq)
2. `/aim-uninit`: **提供**
3. `/aim-help`: **MVP 就做**
4. 升级提示: **MVP 就做**
5. README: **英文主 + 中文版**

### 3.5 命令决策
- 集中式默认根目录: **让用户每次输入**(不预设默认)
- 项目子目录名: **让用户每次输入**
- CLAUDE.md 注入位置: **根目录**(集中式)或项目根(分散式)
- 身份 ID 生成: **`u-<8位随机>`**

---

## 四、文件结构(当前状态)

```
~/Desktop/ai-memory/
├── SKILL.md                              ✅ Skill 总入口(14 命令清单)
├── DEV-PROGRESS.md                       ✅ 本文档
├── README.md                             ✅ 英文主文档
├── README.zh-CN.md                       ✅ 中文版文档
├── CHANGELOG.md                          ✅ 版本历史
├── install.sh                            ✅ 一键安装脚本(可执行)
├── .gitignore                            ✅
├── commands/                             ✅ 全部 14 命令
│   ├── aim-init.md                       ✅
│   ├── aim-add.md                        ✅
│   ├── aim-append.md                     ✅
│   ├── aim-edit.md                       ✅
│   ├── aim-archive.md                    ✅
│   ├── aim-compress.md                   ✅ MVP 简化版
│   ├── aim-status.md                     ✅
│   ├── aim-rebuild.md                    ✅
│   ├── aim-verify.md                     ✅
│   ├── aim-expand.md                     ✅
│   ├── aim-list.md                       ✅
│   ├── aim-help.md                       ✅
│   ├── aim-identity.md                   ✅
│   └── aim-uninit.md                     ✅
├── prompts/                              空(三阶段流水线留待 v0.2)
├── templates/                            ✅
│   ├── INDEX.yaml.tpl                    ✅
│   ├── claude-md-rules.md.tpl            ✅
│   ├── doc-template.html.tpl             ✅
│   └── compressed-template.html.tpl      ✅
└── reference/                            ✅
    └── upgrade-check.md                  ✅
```

---

## 五、任务进度

### 已完成
- ✅ #1 创建项目骨架
- ✅ #2 关联 GitHub 仓库并首次推送(commit `2079b12`)
- ✅ #3 开发 `/aim-init`
- ✅ #4 开发 `/aim-add`
- ✅ #5 开发 `/aim-status`(token 估算、Git diff 落后警告、健康提示)
- ✅ #6 开发 `/aim-rebuild` + `/aim-verify`
- ✅ #7 开发 `/aim-compress`(MVP 简化版)
- ✅ #8 辅助命令: `/aim-help` `/aim-list` `/aim-expand` `/aim-uninit` `/aim-identity` + 升级提示
- ✅ #8 补完 `/aim-append` `/aim-edit` `/aim-archive`(SKILL.md 列出但还没写的)
- ✅ #9 编写 README.md(英文)+ README.zh-CN.md(中文)+ install.sh + CHANGELOG

### 待办
- ⏳ #10 真实项目验证与 Prompt 调优(用 `~/Desktop/persistent-document/` 测试)
  - 选一个测试项目运行完整流程: init → add×3 → status → compress → status → expand → rebuild
  - 验证中文显示、HTML 模板渲染、Git 集成
  - 调优 prompt 让 Claude 在执行命令时行为符合文档预期

---

## 六、关键命令设计要点

### `/aim-init` 流程要点
1. 解析用户身份(读 identity.json 或新建)
2. 询问存储模式(集中式默认 1)
3. 询问根目录(无默认,让用户输入)
4. 询问项目名(中文)和子目录名(英文)
5. 检查是否已初始化
6. 创建目录、生成 INDEX.yaml、注入 CLAUDE.md(追加不覆盖)
7. 可选 Git 初始化
8. 输出结果

### `/aim-add` 流程要点
1. 解析当前项目(读 INDEX.yaml)
2. 解析用户身份
3. 收集内容(参数或询问)
4. 元数据:title/source/tags/filename/doc_id
5. 生成 HTML(用模板)
6. 写文件
7. 更新 INDEX.yaml active 列表(含 contributors、tokens)
8. 可选 git commit
9. 输出结果 + 压缩建议(3+/5+/8+ 三档提示)

### `/aim-compress` MVP 要点
1. 选源文档(默认全部 active)
2. 读取所有源文档全文
3. 检查是否有已有压缩文档(增量合并 vs fresh)
4. **单次 LLM 合并**(非三阶段):
   - 7 个固定章节输出
   - 同主题合并,矛盾内容新覆盖旧、旧入归档区
   - 来源标注 `[来源:文档标题 @ 作者]`
5. 规则校验(正则提取硬信息:版本号、路径、命令、配置)
6. 写入 `compressed-YYYYMMDD.html`
7. **移动**(不复制)源文档到 snapshots
8. 更新 INDEX.yaml: 清 active,设 compressed,记 snapshots
9. 可选 git commit

### 软沙盒规则
- `/aim-add` 永远新建文件,owner = 当前用户
- `/aim-append` `/aim-edit` `/aim-archive` 跨人需确认
- 压缩文档跨人需确认(`__project__` 公共)
- 公共命令(`/aim-status` `/aim-rebuild` `/aim-verify` `/aim-expand` `/aim-list` `/aim-help` `/aim-identity` `/aim-uninit`)不受沙盒约束

### commit message 规范
- `[aim-init] <项目名> - 初始化项目记忆 (<用户名>)`
- `[aim-add] <项目名> - 新建 <文件名> (doc:<doc_id>)`
- `[aim-edit] <项目名> - 修改 <文件名> [cross-user:from <原owner>] (doc:<doc_id>)`
- `[aim-compress] <项目名> - <日期> 压缩归档 (合并 N 篇)`

---

## 七、MVP 必做清单(11 项)

1. ✅ GitHub 仓库公开
2. ✅ install.sh 一键脚本(可执行,带版本缓存初始化)
3. ✅ Git clone 安装方式(已支持)
4. ✅ README.md(英文主) + README.zh-CN.md(中文版)
5. ⏳ 5 分钟快速上手文档(待写,或合并进 README)
6. ✅ 命令清单(SKILL.md 已列 14 个)
7. ✅ CHANGELOG
8. ✅ GitHub Issues 开启(GitHub 默认)
9. ✅ `/aim-uninit` 卸载命令
10. ✅ `/aim-help` 内置帮助
11. ✅ 升级提示机制(reference/upgrade-check.md)

### MVP 不做
- ❌ Plugin Marketplace 发布
- ❌ 视频/博客推广
- ❌ Discord 社区
- ❌ 三阶段压缩流水线(v0.2)
- ❌ MCP 集成(v0.3)
- ❌ GUI

---

## 八、关键技术细节

### 元数据头格式(HTML 注释)
```html
<!-- aim:doc_id=aim-20260621-a3b2f1 title=认证模块设计 tags=auth,security created=2026-06-21 created_by=u-a3b2f1c9 owner=u-a3b2f1c9 status=active source=对话 version=1 -->
```

### INDEX.yaml 结构
```yaml
project: "视频项目"
mode: "central"
root: "/abs/path"
updated: "2026-06-21"

compressed: []        # 单文件,owner=__project__

active:
  - doc_id: "..."
    title: "..."
    file: "..."
    owner: "u-xxx"
    owner_name: "..."
    created: "..."
    created_by: "..."
    updated: "..."
    last_modified_by: "..."
    version: 1
    status: "active"
    source: "..."
    tags: [...]
    permission: "private"
    tokens: 1200
    contributors:
      - { user: "u-xxx", name: "...", last: "..." }

snapshots:
  - date: "2026-06-21"
    reason: "compressed / pre-edit-backup / manual"
    files: [...]
    compressed_into: "..." # 仅 compressed 类型
    archived_from: "..."   # 仅 archived 类型
```

### Token 估算(粗略)
- 中文 1 字符 ≈ 1 token
- 英文 4 字符 ≈ 1 token
- HTML 标签开销 ≈ 50%
- 简化公式: file_size_bytes / 3.5

### 压缩建议阈值
- 3+ active docs → 温和提示
- 5+ active docs → 强烈建议
- 8+ active docs → 警告(膨胀风险)

### 升级提示机制
- `~/.claude/ai-memory/last-version-check.json` 缓存检查结果
- 24 小时检查一次
- 同版本不重复提示(user_dismissed 数组)
- 离线静默跳过,不报错
- `~/.claude/ai-memory/no-auto-check` 文件存在则完全禁用

---

## 九、如何继续开发

### 新会话/压缩后恢复流程
1. 读 `~/Desktop/ai-memory/DEV-PROGRESS.md`(本文档)
2. 读最新任务状态(`TaskList` 或本文档第五节)
3. 用 `TaskUpdate` 把对应任务标 in_progress
4. 按需继续:
   - 写下一个 `commands/<name>.md`
   - 或在 `~/Desktop/persistent-document/` 下做真实项目测试
   - 或调优已有命令文档

### 写命令文档的模板
- frontmatter: `name` + `description`
- 章节: Purpose / Usage / Prerequisites / Flow / Edge Cases / Output Style / Reference
- 中文用户消息,英文代码
- 使用 emoji: ✅ ❌ ⚠️ 📋 📁 📝 💡 📊 🔍 🗜️ 🚨

---

## 十、注意事项

1. **不要修改 git config**(用户偏好)
2. **代理必须用 socks5h**(不是 socks5,前者远端 DNS)
3. **HTTPS 推送需要 PAT**,不要让用户把 PAT 发给我(让他在自己终端 push)
4. **CLAUDE.md 注入用追加**,绝不能覆盖用户原有内容
5. **永远不要删除文件**,只移动到 snapshots/ 或废纸篓
6. **doc_id 一旦生成永不变**(文件改名也不变)
7. **测试时不要污染 `~/Desktop/persistent-document/`**,创建独立测试目录或显式确认
8. **PAT 暴露事件**: 用户之前粘贴了 PAT `ghp_D2eY...` 到对话,**用户必须自己撤销**(GitHub Settings → Developer settings → Personal access tokens → Revoke)

---

**压缩上下文后,直接说"继续开发",我会读此文档恢复状态。**
