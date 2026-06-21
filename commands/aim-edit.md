---
name: aim-edit
description: 修改文档中的现有内容。不同于 /aim-append(仅追加),/aim-edit 会改动现有章节。若不是所有者会触发跨用户确认。总是通过快照备份保留原始版本。
---

# /aim-edit — 修改已有文档

## 用途

修改文档中的现有内容 — 修正错误、更新过时信息、重构结构。与 `/aim-append`(仅追加)不同,`/aim-edit` 可以重写或删除现有章节。

**安全机制**:
1. 编辑前总是把原件备份到 `snapshots/YYYY-MM-DD/`。
2. 非所有者需跨用户确认。
3. 原元数据 `version` 递增;`last_modified_by` 更新。

适用场景:
- 文档信息有误
- 决策更新,文档需要同步
- 为了清晰而重构(不仅是添加)

## 用法

```
/aim-edit <doc_id|filename> [--section <heading>] [instructions]
```

- `doc_id` 或 filename:目标文档。
- `--section <heading>`:把编辑限定到某个章节(按标题文本)。
- `instructions`:描述要改什么的自然语言。

如果没有 instructions:交互式提示用户。

## 前置条件

- 项目已初始化。
- 目标文档存在于 `active` 列表。
- 用户身份已建立。

## 流程

### 步骤 1-4:解析项目、身份、文档、沙盒检查

同 `/aim-append` 步骤 1-4。跨用户确认适用。

### 步骤 5:快照备份(始终执行)

编辑之前:

1. 创建快照目录:`<root>/snapshots/YYYY-MM-DD/`(mkdir -p)。
2. 把当前文件**复制**(不是移动)到 `snapshots/YYYY-MM-DD/<original-filename>`。
3. 该副本作为编辑前备份。

这样活跃文件保留在原位(只是被修改),但编辑前版本以快照形式保存。

### 步骤 6:收集编辑指令

如果提供了 `instructions` 参数:直接使用。

否则提示:

```
请描述要做的修改(自然语言即可,如「把第三段的 JWT 实现改为使用 jose 库」):
[等待用户输入]
```

### 步骤 7:确定编辑范围

如果提供了 `--section`:
- 按标题文本定位章节(大小写不敏感部分匹配)。
- 所有修改限制在该章节范围内。
- 如未找到章节:`未找到章节 [xxx]。文档中的章节: [list]`。

否则:编辑全文任意位置。

### 步骤 8:应用编辑(LLM 轮)

完整读取文档。应用所请求的变更。

**编辑规则**:
1. 保留元数据头(`<!-- aim:... -->`)— 只有 version/updated 字段可变。
2. 不要触碰 `--section` 范围之外的章节。
3. 不要重写整个文档 — 优先最小 diff。
4. 如删除内容:把它移到章节末尾的 `<details>` 折叠块中并加 `[deprecated @ YYYY-MM-DD]` 标注,而非直接删除。软删除。
5. 如添加新内容:插入到语义合适的位置。

生成新的 HTML 内容。

### 步骤 9:Diff 预览

写入前向用户展示统一 diff:

```
📋 修改预览

文件: 2026-06-21-auth-module-design.html
范围: 全文(未限定 --section)

```diff
- 我们使用 jsonwebtoken 库来签发 token。
+ 我们使用 jose 库来签发 token(更现代,支持更多算法)。
```

是否应用? (Y/n/e[手动编辑])
```

- `Y`:写入变更。
- `n`:中止。
- `e`:在用户的 `$EDITOR` 中打开文件手动编辑。

### 步骤 10:写入文件

原子写入(tmp + rename)。更新元数据头:
- `version` += 1
- `updated` = 今天

### 步骤 11:更新 INDEX.yaml

同 `/aim-append` 步骤 9:
- version 递增
- updated = 今天
- last_modified_by = 当前用户
- tokens 重算
- contributors 更新

同时追加到 `snapshots` 列表:

```yaml
- date: "2026-06-21"
  reason: "pre-edit-backup"
  files:
    - "2026-06-21-auth-module-design.html"
  original_of: "aim-20260621-a3b2f1"
  edited_by: "u-a3b2f1c9"
```

### 步骤 12:Git 提交(可选)

```
git add <filename> INDEX.yaml snapshots/
git commit -m "[aim-edit] <PROJECT_NAME> - 修改 <filename> [cross-user:from <name>] (doc:<DOC_ID>)"
```

### 步骤 13:输出结果

```
✅ 文档已修改

📋 操作信息
   目标文档: 认证模块设计 (aim-20260621-a3b2f1)
   修改范围: 全文 / 章节 [xxx]
   操作者: 朱陶锋 (u-a3b2f1c9)
   版本: 2 → 3

📁 文件
   当前: /Users/.../2026-06-21-auth-module-design.html
   备份: /Users/.../snapshots/2026-06-21/2026-06-21-auth-module-design.html

📝 下一步
   - /aim-status              查看更新后状态
   - /aim-expand <doc_id>     对比历史版本
```

## 边界情况

### 情况 A:编辑指令含糊

- LLM 可能产生多种解读。
- 展示所有解读,让用户选:`请选择你想要的修改方式: 1) ... 2) ...`。

### 情况 B:编辑会删除大量内容

- 应用前警告:`本次修改将删除约 N 字内容。建议改为标 [deprecated] 折叠保留? (Y/n)`。

### 情况 C:对高度归属文档的跨用户编辑

- 更强警告:`这是 [张三] 的核心文档,你的修改会影响团队对它的理解。确认?`

### 情况 D:快照目录已有同名文件(同一天多次编辑)

- 给备份文件名追加 `-N` 后缀。

### 情况 E:拍摄快照后取消编辑

- 快照无副作用(只是编辑前状态的备份)。
- 提示:`已保留 pre-edit 快照(snapshots/YYYY-MM-DD/xxx),如不需要可手动删除`。

### 情况 F:目标是压缩文档

- 阻止:`压缩文档不可直接 /aim-edit。如需更新内容,先 /aim-add 新文档,再 /aim-compress 增量合并`。

## 输出风格

- 全程中文。
- 在等宽块中显示 diff。
- 始终显示备份路径。
- 跨用户编辑:显著显示标记。
- emoji:✅ 📋 📁 📝 ⚠️

## 软沙盒行为

- 自己的文档:自由编辑,只需快照备份。
- 他人的文档:每次跨用户确认。
- 压缩文档:禁止直接编辑。

## 参考

- 配套命令:`/aim-append`、`/aim-archive`、`/aim-expand`
- 概念:`reference/soft-sandbox.md`、`reference/document-lifecycle.md`
