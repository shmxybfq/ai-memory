---
name: aim-archive
description: 把文档从活跃列表移到 snapshots 目录。用于不再当前但应保留的文档。可逆操作。
---

# /aim-archive — 归档文档

## 用途

把活跃文档移到 snapshots 目录。该文档不再出现在新会话的"活跃阅读集"中,但保留用于历史参考和 `/aim-expand` 检索。

与 `/aim-compress` 的区别:
- `/aim-compress`:把多篇文档合并为一个压缩文件,然后对原件做快照。
- `/aim-archive`:对单篇文档做快照但不压缩(它不会贡献到压缩文件)。

适用场景:
- 文档过时但不想丢失
- 文档代表一种已弃用的方案,想软删除
- 准备压缩但想把某些文档排除在合并之外

**可逆**:`/aim-expand` 可读取归档文档;手动把文件移回 + 重建 INDEX 可恢复活跃状态。

## 用法

```
/aim-archive <doc_id|filename> [--reason <text>]
```

- `doc_id` 或 filename:目标文档。
- `--reason <text>`:可选,归档原因(记录到 INDEX)。

## 前置条件

- 项目已初始化。
- 目标文档存在于 `active` 列表。
- 用户身份已建立。

## 流程

### 步骤 1-4:解析项目、身份、文档、沙盒检查

同 `/aim-append` 步骤 1-4。

对 `/aim-archive`,跨用户确认适用(归档他人文档会影响项目状态)。

### 步骤 5:确认意图

归档前总是确认:

```
⚠️ 准备归档文档

文档: 认证模块设计 (aim-20260621-a3b2f1)
作者: 朱陶锋
创建: 2026-06-21
版本: 2

归档后:
  - 文件移至 snapshots/2026-06-21/
  - 不再出现在 /aim-status 活跃列表
  - 仍可通过 /aim-expand 检索
  - 不会纳入下次 /aim-compress 的源文档

确认归档? (Y/n)
```

### 步骤 6:确定快照位置

快照路径:`<root>/snapshots/YYYY-MM-DD/<filename>`

如文件已存在(同一天同名归档):追加 `-N` 后缀。

### 步骤 7:移动文件

```
mv <root>/<filename> → <root>/snapshots/YYYY-MM-DD/<filename>
```

使用 `mv`(不是复制)— 文档离开活跃位置。

### 步骤 8:更新文档元数据

读取移动后的文件。更新其元数据头:

```
status=archived
archived_at=2026-06-21
archived_by=u-a3b2f1c9
archive_reason=<reason text or "manual">
```

写回。

### 步骤 9:更新 INDEX.yaml

1. 从 `active` 列表移除条目。
2. 加入 `snapshots` 列表:

```yaml
- date: "2026-06-21"
  reason: "<reason or manual>"
  files:
    - "<filename>"
  archived_from: "<doc_id>"
  archived_by: "u-a3b2f1c9"
```

3. 更新顶层 `updated` 为今天。

### 步骤 10:Git 提交(可选)

```
git add snapshots/ INDEX.yaml
git rm <old active path>  # 文件已移走
git commit -m "[aim-archive] <PROJECT_NAME> - 归档 <filename> [cross-user:from <name>] (doc:<DOC_ID>)"
```

### 步骤 11:输出结果

```
✅ 文档已归档

📋 归档信息
   文档: 认证模块设计 (aim-20260621-a3b2f1)
   原因: 手动归档 / <用户输入的原因>
   操作者: 朱陶锋 (u-a3b2f1c9)

📁 文件位置
   归档至: /Users/.../snapshots/2026-06-21/2026-06-21-auth-module-design.html
   (已从活跃区移除)

📊 项目状态
   活跃: 5 篇(原 6 篇)
   压缩: 1 篇
   快照: 3 个目录

📝 下一步
   - /aim-status              查看更新后状态
   - /aim-expand <doc_id>     如需检索归档内容
   - 手动恢复: mv 文件回根目录 + /aim-rebuild
```

## 边界情况

### 情况 A:归档最后一篇活跃文档

- 允许,但警告:`归档后项目活跃文档为 0。是否仍要继续? (Y/n)`。

### 情况 B:文档有依赖(其他文档引用它)

- 扫描其他活跃文档,查找对本 doc_id 或 title 的引用。
- 如发现引用:警告 `以下文档引用了 [xxx]: [list]。归档后这些引用将成为死链。是否继续? (Y/n)`。

### 情况 C:文档已在压缩文档归档区中被引用

- 那里已经保留。归档活跃副本是安全的。
- 提示:`该文档已存在于压缩文档归档区,本次归档的是 active 副本`。

### 情况 D:今天的快照目录已有很多文件

- 允许,只提示:`今日快照目录已有 N 篇,建议适时 /aim-compress 整合`。

### 情况 E:提供的原因文字很长

- INDEX.yaml 中截断到 200 字符。完整原因写入归档文件元数据。

## 输出风格

- 全程中文。
- 始终显示"from → to"路径变化。
- 项目状态中显示更新计数(前 → 后)。
- emoji:✅ 📋 📁 📊 📝 ⚠️

## 软沙盒行为

- 自己的文档:一次确认即可自由归档。
- 他人的文档:每次需跨用户确认。
- 公共/已归档文档:不适用(已归档)。

## 参考

- 配套命令:`/aim-expand`(反向检索)、`/aim-compress`(通过合并批量归档)
- 概念:`reference/document-lifecycle.md`
