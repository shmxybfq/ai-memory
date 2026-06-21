---
name: aim-rebuild
description: 从文件系统重建 INDEX.yaml。当 INDEX 损坏、不同步或被手动编辑时使用。读取 HTML 文件中的元数据并重建索引。可随时安全运行。
---

# /aim-rebuild — 重建 INDEX.yaml

## 用途

通过读取 HTML 文件中嵌入的元数据头,完全从文件系统重建 `INDEX.yaml`。**文件系统是事实源 — INDEX.yaml 只是可重建的缓存。**

适用场景:
- INDEX.yaml 损坏或无法解析
- INDEX.yaml 被手动编辑,可能不一致
- 通过非 ai-memory 命令(如手动文件操作)添加/删除了文件
- `/aim-verify` 报告 INDEX 与文件系统漂移之后
- 作为失败/中断操作后的恢复步骤

**可随时安全运行。** 写入前总是先备份旧 INDEX.yaml。

## 用法

```
/aim-rebuild [--dry-run]
```

- `--dry-run`:展示会变更什么,但不写入。首次运行推荐。
- 无参数:重建并写入。

## 前置条件

- 项目已初始化(INDEX.yaml 曾经存在;即使损坏,项目目录结构也必须完整)。
- HTML 文件必须有有效的 `<!-- aim:... -->` 元数据头。

## 流程

### 步骤 1:解析当前项目

同 `/aim-status` 步骤 1。如果可能,读取已有 INDEX.yaml(获取项目名、模式、根路径)。

### 步骤 2:备份已有 INDEX.yaml

如果 `INDEX.yaml` 存在:

```
复制 INDEX.yaml → INDEX.yaml.bak.<YYYYMMDD-HHMMSS>
```

保留最近 3 个备份;更早的会被轮转覆盖。未经用户许可不要删除备份。

### 步骤 3:扫描文件系统

遍历项目记忆目录:

```
<root>/                          ← 分散式模式下为 <project>/.ai-memory/
├── INDEX.yaml                   ← (将被覆盖)
├── *.html                       ← 活跃文档
├── compressed-*.html            ← 压缩文档(单文件)
├── snapshots/
│   ├── YYYY-MM-DD/
│   │   └── *.html               ← 归档快照
│   └── ...
└── ...
```

对每个找到的 HTML 文件:

1. 读取前 2KB(头部区域)。
2. 从开头的 `<!-- aim:... -->` 注释中提取元数据。
3. 解析 key=value 对:`doc_id`、`title`、`tags`、`created`、`created_by`、`owner`、`status`、`source`、`version`。
4. 如果没有元数据头:标记为非托管文件(从活跃列表跳过,作为孤儿报告)。
5. 从文件大小估算 tokens。
6. 如果可用,从 git blame 读取 `last_modified_by` 和 `updated`;否则回退到文件 mtime。

### 步骤 4:文件分类

把每个解析的文件分桶:

| 条件 | 桶 |
|---|---|
| `owner=__project__` 且文件名以 `compressed-` 开头 | `compressed` |
| `status=active` 且在根或活跃目录 | `active` |
| `status=archived` 或在 `snapshots/YYYY-MM-DD/` | `snapshots[YYYY-MM-DD]` |
| `status=deprecated` | 列入 `compressed` 归档区(读取压缩文档校验) |
| 无元数据头 | 孤儿(报告,不纳入索引) |

### 步骤 5:重建 INDEX.yaml

构建新结构:

```yaml
project: "<取自旧 INDEX 或根目录 basename>"
mode: "<取自旧 INDEX 或检测:根在已知根列表中为 central,否则为 distributed>"
root: "<绝对路径>"
created: "<取自旧 INDEX 或最早文档 created 日期>"
updated: "<今天>"
version: 1

initialized_by:
  id: "<取自旧 INDEX,或首篇文档 owner>"
  name: "<取自旧 INDEX,或 unknown>"

compressed: [<来自 compressed 桶的列表>]

active: [<来自 active 桶的列表,按 created 倒序>]

snapshots: [<来自 snapshots 桶的 {date, count, files} 列表>]
```

对每个 `compressed` 条目,派生字段:

```yaml
- doc_id: "<取自元数据>"
  file: "<basename>"
  title: "<取自元数据>"
  owner: "__project__"
  created: "<取自元数据>"
  created_by: "<取自元数据>"
  created_by_name: "<从 identity.json 解析>"
  version: <取自元数据,默认 1>
  tokens: <estimated>
  sources_count: <源列表计数>
  sources: [<元数据 'sources' 字段按逗号切分,如 "aim-xxx,aim-yyy" → ["aim-xxx", "aim-yyy"]>]
  contributors:
    - { user: "<created_by>", name: "<resolved>", last: "<created>" }
```

**如果压缩文档的元数据头没有 `sources=` 字段**(此字段添加之前的旧格式):保留 `sources: []` 并在输出中提示:`压缩文档 [xxx] 元数据缺 sources 字段,无法恢复源文档列表`。

对每个 `active` 条目,派生字段:

```yaml
- doc_id: "<取自元数据>"
  title: "<取自元数据>"
  file: "<basename>"
  owner: "<取自元数据>"
  owner_name: "<从 identity.json 或 git config 解析;回退到 id>"
  created: "<取自元数据>"
  created_by: "<取自元数据>"
  updated: "<取自文件 mtime 或 git blame>"
  last_modified_by: "<取自 git blame 最近提交者,或 owner>"
  version: <取自元数据,默认 1>
  status: "<取自元数据,默认 active>"
  source: "<取自元数据,默认 unknown>"
  tags: [<取自元数据>]
  permission: private
  tokens: <estimated>
  contributors:
    - { user: "<owner>", name: "<resolved>", last: "<updated>" }
```

### 步骤 6:试运行 Diff(若 --dry-run)

向用户展示会变更什么:

```
📋 重建预览 (--dry-run)

当前 INDEX.yaml:
  活跃: 5 篇
  压缩: 1 篇
  快照: 2 个

重建后 INDEX.yaml:
  活跃: 6 篇 (+1)
  压缩: 1 篇 (=)
  快照: 2 个 (=)

变更明细:
  + 新增到 active:
    - aim-20260621-xxx (新文档.html)
  - 从 active 移除:
    - aim-20260610-yyy (文件不存在)
  ⚠️ 字段更新:
    - aim-20260615-zzz: title 从「旧标题」改为「新标题」

是否执行重建? (Y/n)
```

等待确认。如果用户拒绝,退出不写入。

### 步骤 7:写入 INDEX.yaml

如果非 dry-run,或用户已确认:

1. 原子写入新 INDEX.yaml(先写到 `INDEX.yaml.tmp`,再 `mv`)。
2. 回读并解析以校验。
3. 如果解析失败:从备份还原并报错中止。

### 步骤 8:输出结果

```
✅ INDEX.yaml 已重建

📋 重建结果
   活跃: 6 篇 (8,400 tokens)
   压缩: 1 篇 (12,500 tokens)
   快照: 2 个目录 (14 篇归档)

📁 文件位置
   /Users/.../INDEX.yaml
   备份: /Users/.../INDEX.yaml.bak.20260621-153022

⚠️ 注意事项
   - 1 个孤儿文件未被纳入索引: old-notes.html
   - 1 个文档丢失文件: aim-20260610-yyy (INDEX 中已移除)

📝 下一步
   - /aim-status    查看完整状态
   - /aim-verify    执行深度一致性检查
```

## 边界情况

### 情况 A:项目根本没有 HTML 文件(刚初始化,INDEX 损坏)

- 重建产生只含项目元数据的空 INDEX。
- 警告:`项目目录下没有任何文档,重建后 INDEX 为空`

### 情况 B:HTML 文件元数据头损坏

- 尝试解析,提取存在的键。
- 用合理默认值填充缺失字段(`status=active`、`version=1` 等)。
- 在输出中标记:`文档 xxx.html 元数据不完整,已用默认值填充`

### 情况 C:多个文件共享同一 doc_id

- 不应发生(doc_id 含随机后缀),但防御性处理。
- 保留第一个,警告重复。
- 建议用户手动排查。

### 情况 D:压缩文档引用了已缺失的源文档

- 如果压缩文档归档区引用的 doc_id 在磁盘上已不存在:这是预期的(它们已被归档)。
- 无需动作;压缩文档本身保存了内容。

### 情况 E:只读文件系统

- 备份或写入时检测。
- 报错:`无法写入 INDEX.yaml,请检查目录权限`

### 情况 F:identity.json 缺失

- 无法从 id 解析 owner_name。
- 回退为显示原始 id(`u-a3b2f1c9`)。
- 警告:`无法解析用户名,请运行 /aim-identity 修复`

## 输出风格

- 用户可见信息用中文。
- 显示完整文件路径。
- emoji 一致使用:✅ 📋 📁 ⚠️ 📝 🔄
- dry-run diff 时,对齐列以提升可读性。
- 始终显示备份路径,便于用户手动回滚。

## 软沙盒行为

- `/aim-rebuild` 是**公共命令** — 无沙盒限制。
- 不修改 HTML 文件,只改 INDEX.yaml。
- 任何用户都可对项目安全运行(这是缓存重建,不是内容变更)。

## 参考

- 配套命令:`/aim-verify`、`/aim-status`
- 概念:`reference/document-lifecycle.md`、`reference/rule-diff-verification.md`
