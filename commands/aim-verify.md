---
name: aim-verify
description: 检查 INDEX.yaml 与文件系统的一致性。报告孤儿文件、缺失文件、元数据漂移和断链引用。只读诊断工具。
---

# /aim-verify — 一致性检查

## 用途

审计 `INDEX.yaml` 与文件系统之间的一致性。检测:
- 孤儿文件(在磁盘上但不在 INDEX 中)
- 缺失文件(在 INDEX 中但磁盘上没有)
- 元数据漂移(INDEX 字段与文件头不一致)
- 断链引用(snapshots 指向空地址、压缩文档缺源)
- Token 计算偏差(INDEX tokens 与实际估算不符)

**只读。** 绝不修改任何内容。搭配 `/aim-rebuild` 来修复此处发现的问题。

适用场景:
- `/aim-rebuild` 之后确认其结果正确
- 周期性健康检查
- `/aim-status` 显示异常时
- 压缩前确保状态干净

## 用法

```
/aim-verify [--fix]
```

- 无参数:仅报告。
- `--fix`:提示应用安全的自动修复(更新陈旧 INDEX 字段、移除断链条目)。不安全的修复仍需人工干预。

## 前置条件

- 项目已初始化。
- INDEX.yaml 可解析(否则建议先 `/aim-rebuild`)。

## 流程

### 步骤 1:解析当前项目

同 `/aim-status` 步骤 1。

### 步骤 2:解析 INDEX.yaml

如果解析失败:停止并提示 `INDEX.yaml 解析失败,请先运行 /aim-rebuild 修复`。

### 步骤 3:校验每个活跃条目

对 `INDEX.yaml` 的 `active` 中每个条目:

1. **文件存在性**:`<root>/<file>` 是否存在?
   - 缺失 → 记录 `MISSING_FILE` 错误。
2. **元数据匹配**:读取 HTML 头,与 INDEX 字段比较:
   - `doc_id` 必须匹配
   - `title` 应匹配(不一致警告)
   - `owner` 必须匹配
   - `status` 必须是 `active`
   - `version` 应匹配
3. **Token 准确性**:从文件大小重新计算 tokens,与 INDEX `tokens` 字段比较。
   - 偏差 > 20% 警告(INDEX 陈旧)。
4. **贡献者一致性**:`contributors` 中每个名字都应能通过 identity.json 或 git config 解析。
5. **日期合理性**:`created <= updated`,且都合理(不在未来,不早于项目初始化)。

### 步骤 4:校验压缩条目

对 `INDEX.yaml` 的 `compressed`:

1. `<root>/<compressed-file>` 文件存在?
2. 元数据头有 `owner=__project__`?
3. 归档区引用的 doc_id — 是否仍有作为活跃文件存在?(可能表示压缩操作未完成。)
4. Token 估算与实际文件大小的合理性检查。

### 步骤 5:校验快照

对 `INDEX.yaml` 的每个 `snapshots` 条目:

1. `<root>/snapshots/<date>/` 目录存在?
2. 文件数与 INDEX 匹配?
3. 内部每个文件元数据有效?

同时扫描文件系统 `<root>/snapshots/*/` 中 INDEX 未记录的目录(孤儿)。

### 步骤 6:扫描孤儿文件

遍历 `<root>/*.html`(分散式:`<project>/.ai-memory/*.html`):

- 任何带有效 `<!-- aim:... -->` 头但不在任何 INDEX 列表中的 HTML 文件 → 孤儿。
- 任何没有元数据头的 HTML 文件 → 非托管(建议用户删除或补充元数据)。

### 步骤 7:交叉引用检查

- INDEX 中每个 `doc_id` 应唯一。
- 每个 `file` 路径应唯一。
- `compressed` 列表至多一条(单文件压缩模型)。
- `last_modified_by` 应在 `contributors` 列表中。

### 步骤 8:对发现分类

按严重度分组:

| 严重度 | 含义 | 示例 |
|---|---|---|
| 🔴 ERROR | 数据丢失风险,必须修复 | 缺失文件、解析失败、doc_id 重复 |
| 🟠 WARN | 漂移,应修复 | tokens 陈旧、title 不一致、旧备份文件 |
| 🟡 INFO | 信息提示 | 孤儿文件(可能是用户自管)、非托管 HTML |
| 🟢 OK | 所有检查通过 | (仅当无其他问题时显示) |

### 步骤 9:应用自动修复(若 --fix)

对每个有安全自动解决方案的 WARN/INFO:

1. **Tokens 陈旧**:重算并更新 INDEX。
2. **Title 不一致**:取文件的 title(以文件系统为准)。
3. **`last_modified_by` 缺失 contributors**:添加。

跳过以下自动修复:
- 🔴 ERROR 项(需要用户判断)
- 孤儿文件(可能是有意的)
- 任何会删除内容的操作

写入前,展示拟定变更并请求确认:

```
📋 准备自动修复 3 项

1. aim-20260620-xxx: tokens 800 → 920 (重新计算)
2. aim-20260615-yyy: title 「旧」→「新」(从文件头读取)
3. aim-20260610-zzz: 添加 contributor u-b1c2d3e4

确认执行? (Y/n)
```

写入前备份 INDEX.yaml(同 `/aim-rebuild`)。

### 步骤 10:输出报告

```
🔍 一致性检查报告

📊 总览
   检查项: 24
   通过: 21
   警告: 2
   错误: 1

🔴 错误 (1)
   1. [MISSING_FILE] aim-20260610-yyy
      INDEX 记录文件 `2026-06-10-old.html`,但文件不存在
      建议: 从 git 恢复,或运行 /aim-rebuild 移除此条目

🟠 警告 (2)
   1. [TOKEN_STALE] aim-20260620-xxx
      INDEX 记录 800 tokens,实际约 920 tokens
      建议: 运行 /aim-verify --fix 自动更新
   2. [TITLE_DRIFT] aim-20260615-yyy
      INDEX: 「旧标题」,文件头: 「新标题」
      建议: 运行 /aim-verify --fix 以文件为准

🟡 提示 (1)
   1. [ORPHAN_FILE] old-notes.html
      文件存在但未纳入 INDEX,可能手动添加
      建议: 如需管理,运行 /aim-add 重新登记

🟢 通过的检查 (21 项)
   ✅ 所有 doc_id 唯一
   ✅ 所有 file 路径唯一
   ✅ compressed 文档完整
   ✅ snapshots 目录一致
   ...

📝 下一步
   - /aim-verify --fix    自动修复可修复项
   - /aim-rebuild         完全重建 INDEX
   - 手动处理错误项后再次运行 /aim-verify
```

## 边界情况

### 情况 A:INDEX.yaml 自身解析失败

- 立即停止。
- 建议:`INDEX.yaml 解析失败,请运行 /aim-rebuild`。
- 不要尝试部分校验。

### 情况 B:项目活跃文档为零且压缩文档为零

- 合法状态(刚初始化)。
- 报告:`🟢 项目为空,无内容可检查`

### 情况 C:identity.json 缺失

- 无法解析贡献者姓名。
- 警告但继续:`无法解析用户名,以 ID 形式显示`

### 情况 D:有 Git 历史可用

- 可选地交叉校验 `last_modified_by` 与实际 git 提交者。
- 如不一致:🟠 WARN(INDEX 可能陈旧)。

### 情况 E:--fix 中途遇到不安全变更

- 中止整个修复批次(不要应用部分修复)。
- 如有写入发生,从备份还原。
- 报告尝试了什么以及为何中止。

### 情况 F:某检查需要网络(如身份同步)

- 跳过该检查,在报告中提示:`跳过 X 检查 (需要网络)`

## 输出风格

- 所有标签用中文。
- 严重度 emoji:🔴 🟠 🟡 🟢
- 问题代码用 `[UPPER_SNAKE_CASE]` 以便 grep。
- 对齐问题编号与描述。
- 总览区始终先行显示计数。
- 长文件列表用 `... 及其他 N 项` 截断,并提供 `--detail` 选项。

## 软沙盒行为

- `/aim-verify` 是**公共命令** — 无沙盒限制。
- 默认只读;`--fix` 模式仅触碰 INDEX.yaml 缓存(不碰内容),对任何用户都视为安全。

## 参考

- 配套命令:`/aim-rebuild`、`/aim-status`
- 概念:`reference/rule-diff-verification.md`
