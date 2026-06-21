# ai-memory

> Claude Code 的跨会话项目记忆层 —— 每次新会话,Claude 直接读取你沉淀的项目知识,无需重新探索代码库。

[English](./README.md) | 中文文档

---

## 为什么需要

每次开启新的 Claude Code 会话,Claude 都从零开始:探索代码库、问相同的问题、慢慢重建你早就建立过的思维模型。这很浪费。

`ai-memory` 给 Claude Code 提供**持久化的项目记忆**。你的技术决策、调试笔记、架构演进 —— 全部以结构化 HTML 文档的形式保留,Claude 在会话开始时直接读取。

可以理解为一个项目专属的"外脑",跨会话、跨压缩周期、甚至跨团队成员地保留上下文。

## 它能做什么

- 📝 **文档沉淀** —— 把知识、决策、踩坑记录为 HTML 文档
- 🗜️ **智能压缩** —— 多篇文档合并为单一双区(当前有效 + 历史归档)压缩文档
- 📊 **状态监控** —— token 使用量、Git 落后警告、健康指标
- 🔍 **反向检索** —— 从快照还原压缩前的细节
- 👥 **多人协作** —— 软沙盒模式,跨用户操作每次显式确认
- 🧹 **自愈机制** —— INDEX.yaml 可重建,一致性校验,快照回滚

## 快速开始

### 安装

```bash
git clone https://github.com/shmxybfq/ai-memory ~/.claude/skills/ai-memory
```

或用安装脚本:

```bash
curl -fsSL https://raw.githubusercontent.com/shmxybfq/ai-memory/main/install.sh | bash
```

> **⚠️ 重要**:安装完成后,**重启 Claude Code**(或开启新会话)。Claude Code 仅在会话启动时扫描 `~/.claude/commands/`,新安装的 `/aim-*` 命令在已运行的会话中不可见。安装脚本会自动创建软链接,注册全部 14 个命令。

### 使用

**前置条件**:安装后已重启 Claude Code(确保 `/aim-*` 命令已注册)。

在任何需要持久记忆的项目里:

```
/aim-init 我的项目
```

Claude Code 会:
1. 询问存储模式(集中式 / 分散式)
2. 询问文档根目录路径
3. 生成 `INDEX.yaml`
4. 将规则追加到 `CLAUDE.md`(追加,绝不覆盖)

然后边工作边记录:

```
/aim-add 我们决定认证用 JWT + Refresh Token,原因是...
```

积累 3-5 篇后,压缩以保持活跃文档精简:

```
/aim-compress
```

下次会话,Claude 读 INDEX.yaml + 压缩文档 + CLAUDE.md 规则,立刻就知道项目的完整历史。

## 命令清单

| 命令 | 用途 |
|---|---|
| `/aim-init` | 初始化项目记忆(每个项目仅一次) |
| `/aim-add` | 添加新文档 |
| `/aim-append` | 在现有文档后追加章节 |
| `/aim-edit` | 修改现有文档(自动快照备份) |
| `/aim-archive` | 归档文档到快照 |
| `/aim-compress` | 合并活跃文档为压缩文档 |
| `/aim-status` | 查看项目状态、token、Git 落后 |
| `/aim-verify` | INDEX 与文件系统一致性检查 |
| `/aim-rebuild` | 从文件系统重建 INDEX.yaml |
| `/aim-expand` | 从快照反向检索细节 |
| `/aim-list` | 列出所有 ai-memory 项目 |
| `/aim-help` | 显示内置帮助 |
| `/aim-identity` | 查看/修改用户身份 |
| `/aim-uninit` | 移除 Skill 注入(保留用户数据) |

在 Claude Code 中运行 `/aim-help` 查看完整说明。

## 核心概念

### 两种存储模式

- **集中式**(默认):所有项目共享一个根目录,一个 CLAUDE.md 管理所有项目。适合个人管理多个私有项目。
- **分散式**:每个项目内嵌 `.ai-memory/` 目录,文档随代码走。适合团队协作和开源项目。

### 软沙盒

每个用户有一个全局身份(`~/.claude/ai-memory/identity.json`)。默认只能直接修改自己的文档,修改他人文档**每次都要显式确认**(不做信任缓存)。这让多人协作变得安全,不需要 OS 级权限控制。

### 双区压缩

压缩文档有两个固定分区:
- **当前有效区**:当前还用的知识,AI 在新会话中优先读这里。
- **历史归档区**:已弃用的内容,标 `[deprecated]`。软删除,不真删。

这让压缩变得保守 —— 宁可保留并降级,也不要丢失信息。

### 元数据嵌入

每篇文档顶部都有 HTML 注释形式的元数据:

```html
<!-- aim:doc_id=aim-20260621-a3b2f1 title=认证模块设计 tags=auth,security created=2026-06-21 created_by=u-a3b2f1c9 owner=u-a3b2f1c9 status=active source=决策 -->
```

这意味着**文件系统是唯一事实来源**。`INDEX.yaml` 是可重建缓存 —— 删掉它,`/aim-rebuild` 会从 HTML 文件重新生成。

## 架构

```
your-project/
├── CLAUDE.md                        ← /aim-init 追加的规则
├── .ai-memory/                       ← (分散式模式)
│   ├── INDEX.yaml                    ← 可重建缓存
│   ├── 2026-06-21-auth.html         ← 活跃文档
│   ├── compressed-20260621.html     ← 压缩文档(双区)
│   └── snapshots/                    ← 历史归档
│       └── 2026-06-21/
│           └── *.html
└── ...
```

集中式模式下,所有项目放在同一个根目录(如 `~/Desktop/persistent-document/`),每个项目一个子目录。

## 设计原则

1. **文件系统是事实来源** —— INDEX.yaml 是可重建缓存
2. **软约束胜过硬权限** —— 确认而非阻塞
3. **保守压缩** —— 宁可保留也不要丢失
4. **基于规则校验** —— 正则提取硬信息,不信任 LLM 自检
5. **Skill 本体与用户数据完全分离** —— 卸载不删数据

## 版本

当前:**0.1.0**(MVP)

Skill 每天自动检查 GitHub 是否有新版本。若有,在会话开始时以非阻塞方式提示,并附上升级命令。

查看 [CHANGELOG.md](./CHANGELOG.md) 了解版本历史。

## 常见问题

**问:支持其他 AI 编程工具吗(Cursor、Windsurf 等)?**

答:暂不支持。MVP 仅支持 Claude Code。MCP 集成已在路线图中(v0.3+),届时可跨工具。

**问:INDEX.yaml 损坏了怎么办?**

答:运行 `/aim-rebuild`。它会读取 HTML 文件中的元数据,完整重建 INDEX。重建前会备份原 INDEX。

**问:能在 Claude Code 之外编辑文档吗?**

答:可以。HTML 文件就是普通 HTML,用任何编辑器都可以改。下次运行 `/aim-status` 或 `/aim-rebuild` 时,ai-memory 会检测差异并自动同步。

**问:数据会被发送到任何地方吗?**

答:不会。所有数据都在本地。唯一的网络调用是每天一次的版本检查(访问 GitHub 公开 API),可以通过 `~/.claude/ai-memory/no-auto-check` 文件禁用。

**问:怎么卸载?**

答:`/aim-uninit` 移除 Skill 在项目 CLAUDE.md 中的注入(保留文档)。加 `--global` 移除 Skill 本体。加 `--purge` 同时删除项目数据(进 macOS 废纸篓,可恢复)。

## 协议

MIT —— 见 [LICENSE](./LICENSE)。

## 贡献

欢迎在 [github.com/shmxybfq/ai-memory](https://github.com/shmxybfq/ai-memory) 提交 Issue 和 PR。
