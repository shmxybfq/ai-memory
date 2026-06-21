# Upgrade Check Mechanism

## Overview

ai-memory checks GitHub for newer versions and informs the user when an update is available. The check is **non-blocking** and **respectful** — never auto-updates, never nags more than once per session.

## When It Runs

The upgrade check triggers at the moment Claude Code loads the Skill (i.e., when the user starts a new session in a project that has ai-memory's CLAUDE.md rules injected).

To avoid hitting GitHub on every session:

```
Read ~/.claude/ai-memory/last-version-check.json
```

If file age < 24 hours: skip the check, use cached result.
If file age >= 24 hours or file missing: do the check.

## How It Checks

Use a lightweight GitHub API call:

```
curl -sS https://api.github.com/repos/shmxybfq/ai-memory/releases/latest
```

Parse the response for `tag_name` (e.g., `v0.2.0`).

Compare to local version (from `SKILL.md` frontmatter `version: 0.1.0`).

**Offline handling**: if the curl fails (timeout, no network), silently skip. Never error out on a version check.

## What It Stores

Cache file: `~/.claude/ai-memory/last-version-check.json`

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

The `user_dismissed` array tracks versions the user has seen and dismissed, so we don't nag them about the same version twice.

## How It Prompts

If `latest_version > current_version` AND `latest_version` not in `user_dismissed`:

Show the user at session start (after their first interaction, not as the very first message):

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

Add `latest_version` to `user_dismissed` so it won't show again until a newer version appears.

## Behavioral Rules

1. **Never auto-update.** Only inform; the user runs the upgrade command themselves.
2. **Never block.** If GitHub is unreachable, fail silently.
3. **Never nag.** Once per version per machine.
4. **Never interrupt mid-task.** Show only at session start or when the user explicitly asks via `/aim-identity` or `/aim-help`.
5. **Always provide the upgrade command.** Don't make the user hunt for it.

## Manual Trigger

Users can manually check via:

```
/aim-identity --check-updates
```

Forces a fresh check (bypasses the 24h cache) and shows the result.

## Install.sh Interaction

When install.sh runs, it should:
1. Pull the latest from GitHub.
2. Update `~/.claude/ai-memory/last-version-check.json` with the installed version as both `current` and `latest`.
3. Clear `user_dismissed` for the newly-installed version.

This ensures a freshly-installed upgrade doesn't immediately prompt "new version available" for the version the user just installed.

## Privacy

The upgrade check sends only a GET to GitHub's public API. No user data, no telemetry, no identifiers. The cache file is local-only.

If the user prefers no network checks at all, they can set:

```
~/.claude/ai-memory/no-auto-check
```

(any file with that name disables the check entirely)
