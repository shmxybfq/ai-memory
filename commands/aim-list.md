---
name: aim-list
description: 列出本机上由 ai-memory 管理的所有项目。扫描已知根目录和分散式项目标记。只读概览。
---

# /aim-list — 列出所有项目

## 用途

展示本机上所有已初始化 ai-memory 的项目。帮助用户:
- 回忆项目记忆存在哪里
- 在项目之间切换上下文
- 审计哪些项目在用 ai-memory

适用场景:
- 忘了某个项目的记忆存在哪里
- 想概览自己的 ai-memory 使用情况
- 设置新机器,检查已初始化了哪些

## 用法

```
/aim-list [--mode <central|distributed|all>]
```

- 无参数:列出全部(默认)。
- `--mode central`:只列集中式项目。
- `--mode distributed`:只列分散式项目。

## 前置条件

无。

## 流程

### 步骤 1:扫描集中式项目

读取 `~/.claude/ai-memory/projects.json`(已知根的注册表)。

对每个注册的根:
1. 列出子目录。
2. 对每个子目录检查 `INDEX.yaml` 是否存在。
3. 如果存在,解析并提取:项目名、模式、创建日期、文档计数。

同时扫描默认根 `~/Desktop/persistent-document/`(即使不在注册表中)。

### 步骤 2:扫描分散式项目

遍历常见代码目录,查找 `.ai-memory/INDEX.yaml`:

默认扫描位置:
- `~/Desktop/`
- `~/Documents/`
- `~/Projects/`(如存在)
- `~/code/`(如存在)
- `~/dev/`(如存在)

深度限制为 3 层,避免扫描整个文件系统。

对每个找到的 `.ai-memory/INDEX.yaml`:
1. 解析它。
2. 提取项目信息。
3. 记录绝对路径。

### 步骤 3:为每个项目解析身份

对每个项目的 `initialized_by.id`,尝试解析为姓名:
- 检查 `~/.claude/ai-memory/identity.json`(若匹配当前用户)。
- 否则显示原始 ID。

### 步骤 4:计算汇总统计

对每个项目:
- 活跃文档数 + 总 tokens
- 压缩文档数 + tokens
- 快照计数
- 最近更新日期
- 距上次活动的天数

### 步骤 5:排序与分组

按最近更新排序(最新优先)。

如未指定 `--mode`,按模式分组(集中式 vs 分散式)。

### 步骤 6:输出

```
📋 ai-memory 项目清单 (共 4 个项目)

🗂️ 集中式 (3 个)
  1. 视频项目
     📁 /Users/.../persistent-document/bauto-video
     📊 活跃 6 / 压缩 1 / 快照 2 | 21,000 tokens
     📅 最近更新: 2026-06-21 (今天)
     👤 初始化: 朱陶锋 (u-a3b2f1c9)

  2. 助手项目
     📁 /Users/.../persistent-document/cf-zs-rn
     📊 活跃 3 / 压缩 0 / 快照 1 | 5,200 tokens
     📅 最近更新: 2026-06-18 (3 天前)
     👤 初始化: 朱陶锋 (u-a3b2f1c9)

  3. 卡片项目
     📁 /Users/.../persistent-document/baby-card-app
     📊 活跃 12 / 压缩 2 / 快照 4 | 45,000 tokens
     ⚠️ 最近更新: 2026-05-10 (42 天前,可能已停滞)
     👤 初始化: 朱陶锋 (u-a3b2f1c9)

📂 分散式 (1 个)
  4. open-source-tool
     📁 /Users/.../projects/open-source-tool/.ai-memory
     📊 活跃 2 / 压缩 0 / 快照 0 | 1,800 tokens
     📅 最近更新: 2026-06-20 (昨天)
     👤 初始化: 朱陶锋 (u-a3b2f1c9)

💡 提示
  - 卡片项目 42 天未更新,考虑 /aim-archive 归档
  - 总计 73,000 tokens 在所有项目中
```

## 边界情况

### 情况 A:完全没有初始化的项目

```
📋 ai-memory 项目清单

尚未初始化任何项目。
运行 /aim-init <项目名> 开始。
```

### 情况 B:某项目目录中 INDEX.yaml 损坏

- 在列表中跳过该项目。
- 末尾提示:`⚠️ 项目 [xxx] 的 INDEX.yaml 损坏,建议运行 /aim-rebuild`。

### 情况 C:扫描发现不在 projects.json 注册表中的项目

- 自动加入注册表(集中式模式)。
- 输出中标注:`(本次新发现,已加入注册表)`。

### 情况 D:文件系统扫描很慢(home 目录巨大)

- 每个 top-level 目录 5 秒超时。
- 提示:`扫描超时,可能遗漏部分分散式项目`。

### 情况 E:分散式项目的 `.ai-memory/` 存在但 INDEX.yaml 缺失

- 看起来是半初始化项目。
- 提示:`⚠️ [xxx] 有 .ai-memory/ 但无 INDEX.yaml,可能初始化未完成`。

## 输出风格

- 全程使用中文。
- 按模式分组并使用章节标题(🗂️ 集中式 / 📂 分散式)。
- 每个项目:序号、名称、路径、统计、日期、所有者。
- 对陈旧(>30 天)或损坏的项目用 ⚠️。
- 长路径用 `...` 中间截断。
- 末尾始终显示 token 总和。

## 软沙盒行为

- 公共命令 — 无限制。
- 显示所有项目,不论初始化者是谁(这是机器级清单)。

## 参考

- 读取 `~/.claude/ai-memory/projects.json` 获取集中式根。
- 配套命令:`/aim-init`、`/aim-status`、`/aim-uninit`
