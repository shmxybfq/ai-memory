# 升级检查机制

## 概览

ai-memory 会检查 GitHub 是否有更新版本,并在有新版本时告知用户。该检查是**非阻塞**且**克制**的 — 绝不自动更新,每次会话最多提示一次。

## 何时运行

升级检查在 Claude Code 加载 Skill 时触发(即用户在已注入 ai-memory 的 CLAUDE.md 规则的项目中开启新会话时)。

为避免每次会话都访问 GitHub:

```
读取 ~/.claude/ai-memory/last-version-check.json
```

如果文件年龄 < 24 小时:跳过检查,使用缓存结果。
如果文件年龄 >= 24 小时或文件缺失:执行检查。

## 如何检查

使用轻量级 GitHub API 调用:

```
curl -sS https://api.github.com/repos/shmxybfq/ai-memory/releases/latest
```

解析响应中的 `tag_name`(如 `v0.2.0`)。

与本地版本(取自 `SKILL.md` frontmatter 的 `version: 0.1.0`)比较。

**离线处理**:如果 curl 失败(超时、无网络),静默跳过。版本检查绝不报错。

## 存储什么

缓存文件:`~/.claude/ai-memory/last-version-check.json`

```json
{
  "checked_at": "2026-06-21T15:30:22Z",
  "latest_version": "0.2.0",
  "current_version": "0.1.0",
  "release_url": "https://github.com/shmxybfq/ai-memory/releases/tag/v0.2.0",
  "release_notes_excerpt": "Added three-stage compression pipeline...",
  "user_dismissed": ["v0.2.0"]
}
```

`user_dismissed` 数组记录用户已看过并忽略的版本,避免就同一版本重复打扰。

## 如何提示

如果 `latest_version > current_version` 且 `latest_version` 不在 `user_dismissed` 中:

在会话开始时(用户首次交互之后,不要作为首条消息)向用户展示:

```
ℹ️ ai-memory 有新版本

当前: 0.1.0
最新: 0.2.0

主要更新:
  - 三阶段压缩流水线(分析 → 合并 → 校验)
  - 跨工具支持(MCP 集成)
  - 性能优化

如何升级:
  cd ~/.claude/skills/ai-memory && git pull
  (或重新运行 install.sh)

本次会话不再提示。如需永久跳过此版本:
  运行 /aim-identity --skip-version 0.2.0
```

把 `latest_version` 加入 `user_dismissed`,这样在出现更新版本前不会再次显示。

## 行为规则

1. **绝不自动更新。** 仅告知;升级命令由用户自己执行。
2. **绝不阻塞。** 如果 GitHub 不可达,静默失败。
3. **绝不打扰。** 每个版本每台机器仅提示一次。
4. **绝不在任务中途打断。** 仅在会话开始时显示,或用户通过 `/aim-identity` 或 `/aim-help` 显式询问时。
5. **始终提供升级命令。** 不要让用户到处找。

## 手动触发

用户可手动检查:

```
/aim-identity --check-updates
```

强制重新检查(绕过 24h 缓存)并显示结果。

## install.sh 交互

当 install.sh 运行时,应:
1. 从 GitHub 拉取最新。
2. 更新 `~/.claude/ai-memory/last-version-check.json`,把已安装版本同时作为 `current` 和 `latest`。
3. 清除新安装版本的 `user_dismissed`。

这确保刚装好的升级不会立即提示"有新版本"(刚装的就是这个版本)。

## 隐私

升级检查仅向 GitHub 公开 API 发送 GET 请求。无用户数据、无遥测、无标识符。缓存文件仅本地。

如果用户不希望做任何网络检查,可设置:

```
~/.claude/ai-memory/no-auto-check
```

(任何以该名称存在的文件都会完全禁用检查)
