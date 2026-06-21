---
name: aim-identity
description: View or modify user identity. The identity is global (one per machine) and used to attribute documents across all projects.
---

# /aim-identity — Manage User Identity

## Purpose

View or modify the global user identity stored at `~/.claude/ai-memory/identity.json`. The identity is:
- **Global** — one identity per machine/user, shared across all projects.
- **Persistent** — created once, used forever unless explicitly changed.
- **Attribution** — every doc you create/edit records your identity.

Use this command when:
- First time setup (alternative to `/aim-init`'s identity step)
- Your name changed (e.g., legal name change, display preference)
- Multiple people share a machine and you need to switch
- Troubleshooting "wrong author on my docs"

## Usage

```
/aim-identity                    # View current identity
/aim-identity --set-name <name>  # Change display name
/aim-identity --reset            # Regenerate user ID (rarely needed)
```

## Prerequisites

None for viewing. For modification, must have write access to `~/.claude/ai-memory/`.

## Flow

### Step 1: Read Current Identity

```
Read ~/.claude/ai-memory/identity.json
```

### Step 2: Branch by Mode

#### View mode (no flags)

Display:

```
👤 当前用户身份

ID:    u-a3b2f1c9
姓名:  朱陶锋
创建:  2026-06-15
Git:   zhu-taofeng(若已关联)

📊 使用情况
  关联项目: 4 个
  创建文档: 23 篇
  最近活跃: 2026-06-21(今天)

📝 修改
  改名: /aim-identity --set-name <新名字>
  重置 ID: /aim-identity --reset(谨慎,会导致历史文档归属显示异常)
```

#### --set-name mode

1. Validate new name (non-empty, reasonable length < 50 chars).
2. Backup current identity.json.
3. Update `name` field.
4. Keep `id` unchanged.
5. Inform user: docs already created will keep the old name in their `contributors` history (we don't rewrite history), but new docs will use the new name.

```
✅ 名字已更新
  旧: 朱陶锋
  新: 朱陶锋(新)

⚠️ 注意
  已创建的 23 篇文档仍保留旧名字在贡献者列表中。
  新文档将使用新名字。
  如需同步历史,需手动运行 /aim-rebuild(会读取最新身份)。
```

#### --reset mode (regenerate ID)

1. Strong warning first:

```
🚨 重置用户 ID 是高风险操作

当前 ID: u-a3b2f1c9
新 ID:   u-<new random>

影响:
  - 你过去创建的所有文档,其 owner 字段仍是旧 ID
  - 软沙盒判定会认为你不是这些文档的 owner
  - 需要手动 /aim-rebuild 才能更新归属

通常仅在以下情况重置:
  - ID 意外泄露需要换新
  - 多人共用账号导致身份混淆

确认重置? (Y/n)
```

2. On confirm: backup, regenerate, write.
3. Suggest `/aim-rebuild` for each project to update ownership.

### Step 3: Output

See format in each branch above.

## Edge Cases

### Case A: identity.json doesn't exist

- Trigger creation flow (same as `/aim-init` Step 1).
- Try git config user.name first, ask user to confirm.

### Case B: identity.json corrupted

- Backup as `identity.json.bak.<timestamp>`.
- Re-run creation flow.
- Note: `原身份文件已备份为 identity.json.bak.xxx`。

### Case C: New name contains special characters

- Allow Chinese, letters, numbers, spaces, hyphens, underscores.
- Reject emojis and control chars.
- On invalid: `名字包含不允许的字符,请使用中文/英文/数字/空格/连字符`。

### Case D: Read-only home directory

- Error: `无法写入 ~/.claude/ai-memory/,请检查权限`。

## Output Style

- Use Chinese throughout.
- Show full ID (don't truncate).
- Use 👤 📊 📝 ⚠️ 🚨 emojis.
- Always show the impact of changes (don't let user blindly reset).

## Soft Sandbox Behavior

- Identity management is **global**, not project-scoped.
- Any user can view the current identity.
- Modifications should be done by the machine owner.

## Reference

- Used by: `/aim-init` (creation), `/aim-add` (attribution), `/aim-rebuild` (resolution)
- Stored at: `~/.claude/ai-memory/identity.json`
