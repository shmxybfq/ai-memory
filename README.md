# ai-memory

> Cross-session project memory layer for Claude Code — every new session, Claude reads your accumulated project knowledge directly instead of rediscovering the codebase.

[中文文档](./README.zh-CN.md) | English

---

## Why

Every time you start a new Claude Code session, Claude begins from scratch: it explores your codebase, asks the same questions, and slowly rebuilds the mental model you already had. This is wasteful.

`ai-memory` solves this by giving Claude Code a **persistent project memory**. Your technical decisions, debugging notes, architecture evolution — all preserved as structured HTML documents that Claude reads at session start.

Think of it as a project-specific external brain that survives across sessions, compression cycles, and even team members.

## What It Does

- 📝 **Document sedimentation** — Record knowledge, decisions, debugging notes as HTML docs
- 🗜️ **Smart compression** — Merge many docs into one dual-zone (active + archive) compressed file
- 📊 **Status monitoring** — Token usage, Git drift warnings, health indicators
- 🔍 **Reverse retrieval** — Expand compressed topics back to original detail from snapshots
- 👥 **Multi-user collaboration** — Soft sandbox with explicit cross-user confirmation
- 🧹 **Self-healing** — Rebuildable INDEX.yaml, consistency verification, snapshot-based rollback

## Quick Start

### Install

```bash
git clone https://github.com/shmxybfq/ai-memory ~/.claude/skills/ai-memory
```

Or with the install script:

```bash
curl -fsSL https://raw.githubusercontent.com/shmxybfq/ai-memory/main/install.sh | bash
```

### Use

In any project where you want persistent memory:

```
/aim-init my-project
```

Claude Code will:
1. Ask for storage mode (centralized vs distributed)
2. Ask for document root path
3. Generate `INDEX.yaml`
4. Inject rules into `CLAUDE.md` (appended, never overwrites)

Then record knowledge as you work:

```
/aim-add We decided to use JWT with refresh tokens for auth because...
```

After 3-5 docs, compress to keep the active reading set small:

```
/aim-compress
```

Next session, Claude reads `INDEX.yaml` + compressed doc + CLAUDE.md rules, and immediately knows your project's history.

## Commands

| Command | Purpose |
|---|---|
| `/aim-init` | Initialize project memory (one-time per project) |
| `/aim-add` | Add new document |
| `/aim-append` | Append section to existing doc |
| `/aim-edit` | Modify existing doc (with snapshot backup) |
| `/aim-archive` | Move doc to snapshots |
| `/aim-compress` | Merge active docs into compressed file |
| `/aim-status` | Show project state, token usage, Git drift |
| `/aim-verify` | Consistency check between INDEX and filesystem |
| `/aim-rebuild` | Rebuild INDEX.yaml from filesystem |
| `/aim-expand` | Reverse-search snapshots for detail |
| `/aim-list` | List all projects with ai-memory |
| `/aim-help` | Show built-in help |
| `/aim-identity` | View/modify user identity |
| `/aim-uninit` | Remove Skill injections (keeps user data) |

Run `/aim-help` in Claude Code for full details.

## Core Concepts

### Two Storage Modes

- **Central mode** (default): All projects share one root directory. One `CLAUDE.md` manages all projects. Best for individuals juggling multiple private projects.
- **Distributed mode**: Each project embeds `.ai-memory/` inside its codebase. Best for team collaboration and open source — memory travels with the repo.

### Soft Sandbox

Each user has a global identity (`~/.claude/ai-memory/identity.json`). By default, you can only directly modify your own docs. Editing someone else's doc triggers an explicit confirmation **every time** (no trust caching). This makes collaboration safe without OS-level permissions.

### Dual-Zone Compression

The compressed doc has two fixed zones:
- **Active zone**: Current valid knowledge. AI reads this first in new sessions.
- **Archive zone**: Deprecated content, marked `[deprecated]`. Soft-deleted, not removed.

This keeps compression conservative — better to keep and demote than to lose information.

### Metadata Embedding

Each document carries metadata in an HTML comment at the top:

```html
<!-- aim:doc_id=aim-20260621-a3b2f1 title=Auth Module Design tags=auth,security created=2026-06-21 created_by=u-a3b2f1c9 owner=u-a3b2f1c9 status=active source=decision -->
```

This means **the filesystem is the source of truth**. `INDEX.yaml` is a rebuildable cache — delete it, and `/aim-rebuild` regenerates it from the HTML files.

## Architecture

```
your-project/
├── CLAUDE.md                        ← Rules appended by /aim-init
├── .ai-memory/                       ← (distributed mode)
│   ├── INDEX.yaml                    ← Rebuildable cache
│   ├── 2026-06-21-auth.html         ← Active docs
│   ├── compressed-20260621.html     ← Compressed doc (dual-zone)
│   └── snapshots/                    ← Historical archives
│       └── 2026-06-21/
│           └── *.html
└── ...
```

For central mode, all projects live under one root (e.g., `~/Desktop/persistent-document/`), each in its own subdir.

## Design Principles

1. **Filesystem is source of truth** — INDEX.yaml is rebuildable cache
2. **Soft constraints over hard permissions** — confirmation, not blocking
3. **Conservative compression** — better to keep than to lose
4. **Rule-based verification** — regex extract hard info, don't trust LLM self-check
5. **Skill body and user data completely separated** — uninstall keeps data

## Version

Current: **0.1.0** (MVP)

The Skill auto-checks GitHub for newer versions once per day. If an update is available, it shows a non-blocking notice at session start with the upgrade command.

See [CHANGELOG.md](./CHANGELOG.md) for version history.

## FAQ

**Q: Does this work with other AI coding tools (Cursor, Windsurf, etc.)?**

A: Not yet. MVP is Claude Code only. MCP integration is on the roadmap (v0.3+) to make it cross-tool.

**Q: What if my INDEX.yaml gets corrupted?**

A: Run `/aim-rebuild`. It reads metadata from HTML files and reconstructs INDEX entirely. The original INDEX is backed up before rebuild.

**Q: Can I edit documents outside of Claude Code?**

A: Yes. The HTML files are plain HTML — edit them however you like. Next time you run `/aim-status` or `/aim-rebuild`, ai-memory detects drift and reconciles.

**Q: Is my data sent anywhere?**

A: No. Everything is local. The only network call is a version check to GitHub's public API (once per day), and you can disable that with `~/.claude/ai-memory/no-auto-check`.

**Q: How do I uninstall?**

A: `/aim-uninit` removes the Skill's CLAUDE.md injection from a project (keeps your docs). Add `--global` to remove the Skill itself. Add `--purge` to also delete project data (goes to macOS Trash, recoverable).

## License

MIT — see [LICENSE](./LICENSE).

## Contributing

Issues and PRs welcome at [github.com/shmxybfq/ai-memory](https://github.com/shmxybfq/ai-memory).
