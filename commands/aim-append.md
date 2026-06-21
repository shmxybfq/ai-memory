---
name: aim-append
description: 向已有文档追加新章节。保留原内容,在末尾添加新章节。若文档所有者不同,会触发跨用户确认。
---

# /aim-append — 向已有文档追加内容

## 用途

在已有文档末尾追加新章节,原内容保持不变。适用于:
- 给决策日志加更新
- 记录后续调试笔记
- 给调研文档添加新发现

与 `/aim-edit`(修改现有内容)和 `/aim-add`(创建新文件)不同。

## 用法

```
/aim-append <doc_id|filename> [content]
```

- `doc_id` 或 filename:目标文档。
- `content`:可选,新章节内容。如省略,提示用户输入。

## 前置条件

- 项目已初始化。
- 目标文档存在(在 INDEX.yaml 的 `active` 列表中,文件在磁盘上)。
- 用户身份已建立。

## 流程

### 步骤 1:解析当前项目

同 `/aim-add` 步骤 1。

### 步骤 2:解析用户身份

读取 `~/.claude/ai-memory/identity.json`。必需。

### 步骤 3:解析目标文档

匹配 `<doc_id|filename>` 参数:
1. 尝试在 INDEX.yaml 的 `active` 中精确匹配 `doc_id`。
2. 尝试匹配 filename(basename)。
3. 尝试部分 title 匹配(多个则交互确认)。

如果在 active 中找不到:也检查压缩文档的归档区(无法向归档追加 — 建议 `/aim-expand` 先展开,或改用 `/aim-add`)。

如果任何地方都找不到:`文档 [xxx] 不存在。/aim-list 查看所有文档`。

将目标条目保存为 `DOC`。

### 步骤 4:检查软沙盒(跨用户)

比较 `DOC.owner` 与当前用户 ID。

**同一用户**:无需确认,直接继续。

**不同用户**(跨沙盒):

```
⚠️ 跨用户操作

文档 [xxx] 的 owner 是 [张三] (u-b1c2d3e4)。
你 [朱陶锋] (u-a3b2f1c9) 不是 owner。

是否确认追加内容到他人文档?
本次操作会在文档中标注 [cross-user:from 朱陶锋 @ 2026-06-21]。

确认? (Y/n)
```

按项目规则:不做缓存,每次跨用户操作都要重新确认。

**如果拒绝**:中止并提示 `操作已取消`。

### 步骤 5:收集新章节内容

如果提供了参数:作为 `RAW_CONTENT`。
否则提示:

```
请输入要追加的内容(可以是补充说明、新发现、后续进展等):
[等待用户输入]
```

### 步骤 6:确定章节元数据

询问用户(带合理默认):

```
章节标题(可选,默认「更新 - YYYY-MM-DD」):
```

保存为 `SECTION_TITLE`。

### 步骤 7:生成 HTML 章节

把 RAW_CONTENT 结构化为自包含 HTML 章节:

```html
<section class="appendix">
  <h2>{{SECTION_TITLE}}</h2>
  <p class="meta">追加 by {{USER_NAME}} ({{USER_ID}}) @ {{TODAY}}</p>
  {{CONTENT}}
</section>
```

如果是跨用户,添加 `data-cross-user` 属性和内联标注。

### 步骤 8:插入到文档

1. 完整读取目标 HTML 文件。
2. 找到末尾的元数据块(`<div class="highlight">文档元数据...</div>`)。
3. 把新章节插入到元数据块**之前**。
4. 更新元数据头注释:
   - `version` 加 1。
   - `updated` 更新为今天。
5. 保存文件(原子写入:tmp + rename)。

### 步骤 9:更新 INDEX.yaml

对目标文档条目:
- `version`:加 1。
- `updated`:今天。
- `last_modified_by`:当前用户。
- `tokens`:从新文件大小重新计算。
- 如果用户还不在 `contributors` 中则添加:
  ```yaml
  contributors:
    - { user: "u-a3b2f1c9", name: "朱陶锋", last: "2026-06-21" }
  ```

更新顶层 `updated` 为今天。

### 步骤 10:Git 提交(可选)

如果在 git 中:

```
git add <filename> INDEX.yaml
git commit -m "[aim-append] <PROJECT_NAME> - 追加 <SECTION_TITLE> 到 <filename> [cross-user:from <name>] (doc:<DOC_ID>)"
```

仅在适用时包含 `[cross-user:from <name>]`。

### 步骤 11:输出结果

```
✅ 已追加内容

📋 操作信息
   目标文档: 认证模块设计 (aim-20260621-a3b2f1)
   追加章节: 更新 - 2026-06-21
   操作者: 朱陶锋 (u-a3b2f1c9)
   版本: 1 → 2

📁 文件
   /Users/.../2026-06-21-auth-module-design.html

📝 下一步
   - /aim-status     查看更新后状态
   - /aim-edit       如需修改已有内容
```

## 边界情况

### 情况 A:目标文档处于压缩/归档状态

- 无法向压缩文档追加(它是 `__project__` 所有,冻结状态)。
- 建议:改用 `/aim-add` 用新内容创建新文档。

### 情况 B:文档文件损坏(无元数据头)

- 检测:无法解析 `<!-- aim:... -->`。
- 停止:`文档元数据缺失,可能损坏。运行 /aim-rebuild 修复后再试`。

### 情况 C:跨用户确认被拒绝

- 干净中止。无文件变更。

### 情况 D:内容过大(单次追加 >3000 tokens)

- 警告:`追加内容较长(X tokens),建议拆分为独立文档 /aim-add。是否继续? (Y/n)`。

### 情况 E:文档版本变高(>10)

- 多次追加后建议:`文档已追加 10+ 次,建议 /aim-compress 整合到压缩文档`。

## 输出风格

- 全程中文。
- 显式显示版本号递增。
- 跨用户操作:输出中始终显示跨用户标记。
- emoji:✅ 📋 📁 📝 ⚠️

## 软沙盒行为

- 自己的文档:自由追加,无需确认。
- 他人的文档:每次显式确认,无缓存。
- 压缩文档(`owner=__project__`):对所有人都视为跨用户(因为它是共享的)。

## 参考

- 配套命令:`/aim-add`、`/aim-edit`、`/aim-archive`
- 概念:`reference/soft-sandbox.md`
