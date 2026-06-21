---
name: aim-uninit
description: 从项目中移除 ai-memory Skill 注入。保留所有用户数据(文档、快照、INDEX.yaml)。重新运行 /aim-init 可恢复。
---

# /aim-uninit — 移除 Skill 注入

## 用途

从项目中移除 ai-memory 的痕迹,但不删除用户数据。具体:
- 从 `CLAUDE.md` 中剥离 ai-memory 规则块(标记之间)。
- 从 `~/.claude/ai-memory/projects.json` 中移除项目条目(集中式模式)。
- 保持所有文档、快照、INDEX.yaml、压缩文档不变。

适用场景:
- 想停止在某个项目上使用 ai-memory
- 移交项目并想清理
- 想从头重置并重新初始化(替代方案:手动删除 INDEX.yaml)

**可逆**:对同一项目重新运行 `/aim-init` 会重新检测已有数据并重新注入规则。

## 用法

```
/aim-uninit [--project <name|path>] [--purge] [--global]
```

- 无参数:卸载当前项目(从 cwd 解析)。
- `--project <name>`:按名称或路径卸载指定项目。
- `--purge`:**同时删除用户数据**(文档、快照、INDEX.yaml)。危险。需双重确认。
- `--global`:完全卸载 Skill(移除 `~/.claude/skills/ai-memory/` 或符号链接)。不触碰任何项目数据。

## 前置条件

项目级卸载:
- 项目当前必须已初始化(CLAUDE.md 中有规则,projects.json 中有条目)。

全局卸载:
- Skill 必须安装在 `~/.claude/skills/ai-memory/`。

## 流程

### 步骤 1:确定范围

解析 flag:
- `--global` → 跳到步骤 8(全局卸载)。
- `--purge` → 启用破坏性模式(步骤 7)。
- 其他:项目级卸载。

### 步骤 2:解析目标项目

如果提供了 `--project`:
- 按名称匹配(在 projects.json 中查找)。
- 或按路径前缀匹配。

否则:从 cwd 解析(同 `/aim-add` 步骤 1)。

如果未找到项目:`当前目录不在任何 ai-memory 项目中,无需卸载`。

### 步骤 3:展示将被移除的内容

变更前,展示清晰预览:

```
⚠️ 即将从项目 [视频项目] 移除 ai-memory

将删除:
  - CLAUDE.md 中的 ai-memory 规则块(位于 <!-- ai-memory rules start --> 与 end 标记之间)
  - projects.json 中的项目注册条目

将保留:
  - 所有文档: ~/Desktop/persistent-document/bauto-video/*.html (6 篇)
  - 压缩文档: compressed-20260621.html
  - 快照: snapshots/ (2 个目录)
  - INDEX.yaml(可在重新 /aim-init 时复用)

确认卸载? (Y/n)
```

等待显式确认。默认 n。

### 步骤 4:剥离 CLAUDE.md 规则

读取 CLAUDE.md。定位 ai-memory 规则块:

```
<!-- ai-memory rules start -->
... (规则内容) ...
<!-- ai-memory rules end -->
```

移除该块(含标记)。保留 CLAUDE.md 中其他所有内容。

边界情况:
- 如果未找到标记:提示 `CLAUDE.md 中未找到 ai-memory 规则,跳过此步`。
- 如果 CLAUDE.md 不存在:跳过。
- 如果移除后 CLAUDE.md 为空或仅空白:保留为空文件(不要删除,用户可能对它有规划)。

编辑前备份 CLAUDE.md 为 `CLAUDE.md.bak.<timestamp>`。

### 步骤 5:从 projects.json 移除

读取 `~/.claude/ai-memory/projects.json`。移除该项目根的条目。

如果这是某根下最后一个项目,可选择也移除该根条目。

写回。先备份。

### 步骤 6:保留数据不动

显式不触碰:
- `<root>/*.html`(活跃文档)
- `<root>/compressed-*.html`
- `<root>/snapshots/`
- `<root>/INDEX.yaml`
- `~/.claude/ai-memory/identity.json`(全局,非项目特定)

### 步骤 7:Purge 模式(仅在 --purge 时)

如果设置了 `--purge`,在步骤 3 确认之后,用更强警告再次询问:

```
🚨 危险操作确认 🚨

你选择了 --purge,这会永久删除项目所有数据:
  - 6 篇活跃文档
  - 1 篇压缩文档
  - 2 个快照目录(14 篇归档)
  - INDEX.yaml

此操作不可恢复(除非有 Git 历史或外部备份)。

请输入项目名「视频项目」以确认彻底删除:
> _
```

用户必须键入确切项目名。不匹配:中止。

确认后:
1. 把整个项目记忆目录移到 `~/.Trash/ai-memory-purge-<project>-<timestamp>/`(macOS 废纸篓,30+ 天内可恢复)。
2. 不要直接 `rm -rf` — 始终走废纸篓。
3. 从 projects.json 移除(步骤 5 已完成)。

### 步骤 8:全局卸载(仅在 --global 时)

如果 `--global`:

```
⚠️ 全局卸载 ai-memory Skill

将从以下位置移除 Skill 本体:
  - ~/.claude/skills/ai-memory/ (或 symlink)

不会修改任何项目数据。
但所有 /aim-* 命令将不再可用。

确认全局卸载? (Y/n)
```

确认后:
1. 如果 `~/.claude/skills/ai-memory` 是符号链接:只移除符号链接。
2. 如果是真实目录:移到废纸篓(可恢复)。
3. 保留 `~/.claude/ai-memory/`(用户数据:identity、projects.json)— 那是数据,不是 Skill。
4. **清理 `~/.claude/commands/aim-*.md` 软链接**:这些是 install.sh 创建的(让 `/aim-*` 命令在 Claude Code 中可用)。检查每个 `aim-*.md`,如果是软链接且指向已删除的 skill 目录,移除软链接;如果是真实文件(用户自定义版本),保留不动。

### 步骤 9:输出

#### 项目级卸载(无 --purge)

```
✅ ai-memory 已从项目 [视频项目] 移除

📋 移除内容
  - CLAUDE.md: 已移除 ai-memory 规则块(备份在 CLAUDE.md.bak.20260621-153022)
  - projects.json: 已移除该项目条目

📁 保留的数据(随时可重新初始化)
  - 6 篇活跃文档
  - 1 篇压缩文档
  - 2 个快照目录
  - INDEX.yaml

📝 重新启用
  cd /Users/.../bauto-video
  /aim-init 视频项目
  (会自动检测并复用现有数据)
```

#### 带 --purge

```
✅ 项目 [视频项目] 已彻底清除

📋 已删除
  - 所有文档、压缩文档、快照、INDEX.yaml
  - 已移至废纸篓: ~/.Trash/ai-memory-purge-bauto-video-20260621-153022/
  - 30 天内可从废纸篓恢复

📝 重新开始
  /aim-init 视频项目
```

#### 全局卸载

```
✅ ai-memory Skill 已全局卸载

📋 移除内容
  - ~/.claude/skills/ai-memory/ (移至废纸篓)

📁 保留
  - ~/.claude/ai-memory/ (用户数据:identity.json, projects.json)
  - 各项目的文档与 INDEX.yaml

📝 重新安装
  git clone https://github.com/shmxybfq/ai-memory ~/.claude/skills/ai-memory
```

## 边界情况

### 情况 A:项目未初始化(CLAUDE.md 中无标记,projects.json 中无条目)

- 输出:`项目 [xxx] 未启用 ai-memory,无需卸载`。

### 情况 B:CLAUDE.md 只读

- 报错:`无法修改 CLAUDE.md,请检查文件权限`。
- 建议:`sudo chown $(whoami) CLAUDE.md` 或手动编辑。

### 情况 C:projects.json 损坏

- 跳过该步骤。
- 提示:`projects.json 解析失败,请手动清理项目条目`。

### 情况 D:对无数据项目(只有 CLAUDE.md 注入)执行 --purge

- 只移除注入。
- 提示:`项目无实际数据,仅清理 CLAUDE.md`。

### 情况 E:用户尝试同时使用 --purge 和 --global

- 阻止:`--purge 与 --global 不可同时使用。--global 仅移除 Skill 本体,--purge 针对单个项目数据`。

### 情况 F:macOS 废纸篓不可用(Linux/非 Mac)

- 回退到 `~/.ai-memory-trash/<timestamp>/` 目录。
- 在输出中提示此位置。

## 输出风格

- 全程中文。
- 不可逆/危险步骤用 ⚠️。
- purge 模式用 🚨。
- 始终显示备份和废纸篓路径。
- 末尾给出 📝 重新开始/重新启用 章节,展示恢复路径。

## 软沙盒行为

- 卸载是**破坏性管理操作**。
- 多用户项目需项目所有者确认(所有者未知时任何人可确认)。
- `--purge` 无论用户是谁,都要求键入项目名确认。

## 参考

- 配套命令:`/aim-init`(反向操作)
- 概念:"Skill 本体与用户数据完全分离"(SKILL.md 设计原则 5)
