---
name: aim-identity
description: View or modify the user identity. Identity is global (one per machine) and is used to attribute documents across all projects.
---

# /aim-identity — Manage User Identity

## Purpose

View or modify the global user identity stored at `~/.claude/ai-memory/identity.json`. Identity characteristics:
- **Global** — one identity per machine/user, shared across all projects.
- **Persistent** — created once, used permanently unless explicitly changed.
- **Attribution** — every document you create or edit records your identity.

Use cases:
- First-time setup (as an alternative to the `/aim-init` identity step)
- Name change (e.g. legal name change, display preference)
- Multiple people sharing one machine and needing to switch
- Troubleshooting "my documents show the wrong author"

## Usage

```
/aim-identity                    # View current identity
/aim-identity --set-name <name>  # Change display name
/aim-identity --reset            # Regenerate user ID (rarely needed)
```

## Prerequisites

No prerequisites for viewing. Modifying requires write access to `~/.claude/ai-memory/`.

## Workflow

### Step 1: Read current identity

```
Read ~/.claude/ai-memory/identity.json
```

### Step 2: Branch by mode

#### View mode (no flags)

Display:

```
👤 Current User Identity

ID:    u-a3b2f1c9
Name:  Jane Doe
Created: 2026-06-15
Git:   jane-doe (if linked)

📊 Usage
  Associated projects: 4
  Documents created: 23
  Last active: 2026-06-21 (today)

📝 Changes
  Rename:  /aim-identity --set-name <new-name>
  Reset ID: /aim-identity --reset (caution — breaks ownership display on historical documents)
```

#### --set-name mode

1. Validate the new name (non-empty, reasonable length < 50 characters).
2. Back up the current identity.json.
3. Update the `name` field.
4. Keep `id` unchanged.
5. Inform the user: existing documents retain the old name in their `contributors` history (history is not rewritten), but new documents will use the new name.

```
✅ Name updated
  Old: Jane Doe
  New: Jane Smith

⚠️ Note
  23 existing documents still show the old name in their contributor lists.
  New documents will use the new name.
  To sync history, manually run /aim-rebuild (reads the latest identity).
```

#### --reset mode (regenerate ID)

1. Issue a strong warning first:

```
🚨 Resetting User ID is a High-Risk Operation

Current ID: u-a3b2f1c9
New ID:     u-<new random>

Impact:
  - All documents you previously created still have the old ID as their owner field
  - The soft-sandbox logic will consider you NOT the owner of those documents
  - A manual /aim-rebuild is required to update ownership

Reset is typically only needed when:
  - The ID was accidentally leaked and needs to be replaced
  - Multiple people sharing an account caused identity confusion

Confirm reset? (Y/n)
```

2. After confirmation: back up, regenerate, write.
3. Recommend running `/aim-rebuild` on every project to update ownership.

### Step 3: Output

See the respective branch formats above.

## Edge Cases

### Case A: identity.json does not exist

- Trigger the creation flow (same as `/aim-init` Step 1).
- Try `git config user.name` first, then ask the user to confirm.

### Case B: identity.json is corrupted

- Back it up as `identity.json.bak.<timestamp>`.
- Re-run the creation flow.
- Note: `The original identity file has been backed up to identity.json.bak.xxx`

### Case C: New name contains special characters

- Allow CJK characters, letters, digits, spaces, hyphens, and underscores.
- Reject emojis and control characters.
- If invalid: `Name contains disallowed characters. Please use letters, digits, spaces, hyphens, or underscores.`

### Case D: Home directory is read-only

- Error: `Cannot write to ~/.claude/ai-memory/ — check permissions.`

## Output Style

- Write entirely in English.
- Display the full ID (do not truncate).
- Use 👤 📊 📝 ⚠️ 🚨 emojis.
- Always show the impact of changes (do not let users blindly reset).

## Soft Sandbox Behavior

- Identity management is **global** and does not change with projects.
- Any user can view the current identity.
- Modifications should be performed by the machine owner.

## References

- Used by: `/aim-init` (creation), `/aim-add` (attribution), `/aim-rebuild` (resolution)
- Stored at: `~/.claude/ai-memory/identity.json`
