# Upgrade Check Mechanism

## Overview

ai-memory checks GitHub for newer versions and notifies users when updates are available. The check is **non-blocking** and **unobtrusive** — it never auto-updates, and prompts at most once per session.

## When It Runs

The upgrade check triggers when Claude Code loads the Skill (i.e., when a user starts a new session in a project whose CLAUDE.md rules have the ai-memory injection).

To avoid hitting GitHub on every session:

```
Read ~/.claude/ai-memory/last-version-check.json
```

If the file is less than 24 hours old: skip the check and use the cached result.
If the file is 24+ hours old or missing: perform the check.

## How It Checks

Uses a lightweight GitHub API call:

```
curl -sS https://api.github.com/repos/shmxybfq/ai-memory/releases/latest
```

Parses the `tag_name` from the response (e.g., `v0.2.0`).

Compares it against the local version (taken from the `version: 0.1.0` field in `SKILL.md` frontmatter).

**Offline handling:** If curl fails (timeout, no network), the check is silently skipped. Version checks never produce errors.

## What Is Stored

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

The `user_dismissed` array tracks versions the user has already seen and dismissed, preventing repeated notifications for the same version.

## How It Notifies

If `latest_version > current_version` and `latest_version` is not in `user_dismissed`:

Display the following to the user at session start (after the user's first interaction, not as the very first message):

```
ℹ️ ai-memory has a new version

Current: 0.1.0
Latest:  0.2.0

Key updates:
  - Three-stage compression pipeline (analyze → merge → verify)
  - Cross-tool support (MCP integration)
  - Performance improvements

To upgrade:
  cd ~/.claude/skills/ai-memory && git pull
  (or re-run install.sh)

This notification will not appear again this session. To permanently skip this version:
  run /aim-identity --skip-version 0.2.0
```

Adds `latest_version` to `user_dismissed` so it will not be shown again until a newer version is released.

## Behavior Rules

1. **Never auto-update.** Only notify; the user runs upgrade commands themselves.
2. **Never block.** If GitHub is unreachable, fail silently.
3. **Never pester.** Each version is shown at most once per machine.
4. **Never interrupt mid-task.** Only shown at session start, or when the user explicitly asks via `/aim-identity` or `/aim-help`.
5. **Always provide upgrade commands.** Don't make users hunt for them.

## Manual Trigger

Users can manually check for updates:

```
/aim-identity --check-updates
```

This forces a re-check (bypassing the 24-hour cache) and displays the result.

## install.sh Interaction

When install.sh runs, it should:
1. Pull the latest from GitHub.
2. Update `~/.claude/ai-memory/last-version-check.json`, setting the newly installed version as both `current` and `latest`.
3. Clear `user_dismissed` for the newly installed version.

This ensures a fresh installation does not immediately show a "new version available" notification (since the installed version IS the latest).

## Privacy

The upgrade check sends a GET request only to the GitHub public API. No user data, no telemetry, no identifiers. The cache file is local only.

If users prefer to opt out of all network checks entirely, they can create:

```
~/.claude/ai-memory/no-auto-check
```

(The mere existence of a file with this name will disable checks entirely.)
