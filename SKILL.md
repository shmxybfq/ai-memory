---
name: ai-memory
description: Cross-session project memory layer for Claude Code. Provides document creation, compression, archiving, and retrieval capabilities. Install once, gain persistent project knowledge across sessions.
version: 0.1.0
author: ai-memory
license: MIT
---

# ai-memory

> A cross-session memory layer for Claude Code — every new session, AI reads your accumulated project knowledge instead of re-exploring from scratch.

## What This Skill Does

`ai-memory` gives Claude Code persistent project memory across sessions. Instead of re-exploring your project each time, Claude reads the knowledge you've accumulated.

**Core capabilities:**
- 📝 Document creation (`/aim-add`)
- 🗜️ Dual-zone smart compression (active + archived) (`/aim-compress`)
- 📊 Status monitoring (`/aim-status`)
- 🔍 Reverse search from snapshots (`/aim-expand`)
- 👥 Soft-sandbox multi-user collaboration
- 🧹 Auto rebuild and verification

## Commands

| Command | Purpose | Sandbox |
|---|---|---|
| `/aim-init` | Initialize project memory (one-time) | ❌ |
| `/aim-add` | Add a new document (always creates new file) | ✅ |
| `/aim-append` | Append sections to an existing document | ✅ |
| `/aim-edit` | Modify an existing document | ✅ |
| `/aim-archive` | Archive a document to snapshots | ✅ |
| `/aim-compress` | Compress active documents into dual-zone single file (MVP single-step + rule validation) | ⚠️ Special |
| `/aim-status` | Show project status, token usage, Git drift | ❌ |
| `/aim-rebuild` | Rebuild INDEX.yaml from filesystem | ❌ |
| `/aim-verify` | Check INDEX.yaml vs filesystem consistency | ❌ |
| `/aim-expand` | Reverse search snapshots for details | ❌ |
| `/aim-list` | List all ai-memory projects | ❌ |
| `/aim-help` | Show help for all commands | ❌ |
| `/aim-uninit` | Remove Skill injection (preserve user data) | ❌ |
| `/aim-identity` | View or modify user identity | ❌ |

See `commands/` directory for detailed flows of each command.

## Core Concepts

### Two Storage Modes

- **Centralized mode (default)**: All projects share one document root (e.g. `~/Desktop/persistent-document/`). One CLAUDE.md manages all projects. Suited for individuals managing multiple private projects.
- **Distributed mode**: Each project embeds `.ai-memory/` within its own codebase. Suited for team collaboration and open source.

### Soft Sandbox (Multi-user Collaboration)

Each user has a global identity (`~/.claude/ai-memory/identity.json`). By default, users can only directly modify their own documents. Cross-user operations require **explicit confirmation every time** (no caching).

### Document Lifecycle

```
/aim-add  →  memory/*.html  →  /aim-compress  →  snapshots/YYYY-MM-DD/
                                  ↓
                          compressed.html
                  (dual-zone: active + archived)
```

### Dual-Zone Compression

Compressed documents have two fixed zones:
- **Active zone**: Currently valid knowledge (AI reads first)
- **Archive zone**: Content marked as `[deprecated]` (soft delete, not removed)

This prevents bloat without losing information.

### Embedded Metadata

Each document has metadata in an HTML comment at the top:
```html
<!-- aim:doc_id=aim-20260610-a3b2f1 title=... tags=... created=... created_by=... owner=... status=... -->
```

INDEX.yaml is a **rebuildable cache**, not the source of truth. The filesystem is the source of truth.

## Getting Started

### First-Time Setup
```
1. /aim-init [project-name]
   → Choose mode (centralized/distributed)
   → Choose document root path
   → Generate INDEX.yaml
   → Inject rules into CLAUDE.md (append, don't overwrite)

2. /aim-add [natural language description]
   → Claude structures content into HTML
   → Embeds metadata header
   → Updates INDEX.yaml

3. /aim-status
   → Verify setup is working
```

### Daily Workflow
```
/aim-add       → Record knowledge (anytime)
/aim-status    → Check status (occasionally)
/aim-compress  → Compress when 3-5 docs accumulated
```

## Architecture

```
ai-memory/
├── SKILL.md                  ← This file (entry point)
├── commands/                 ← One .md per slash command (skill internal resource)
├── prompts/                  ← Reserved for v0.2 (not yet created)
├── templates/                ← File templates
│   ├── INDEX.yaml.tpl
│   ├── claude-md-rules.md.tpl
│   ├── doc-template.html.tpl
│   └── compressed-template.html.tpl
└── reference/                ← Internal reference docs
```

### Command Registration Mechanism (Why commands/ exists in two places)

Claude Code has **two independent command systems**:

- **Skills**: Located at `~/.claude/skills/<name>/SKILL.md`, triggered via `/<skill-name>` to load the entire skill
- **Slash Commands**: Located at `~/.claude/commands/*.md`, triggered directly via `/<command-name>`

**`commands/*.md` inside a Skill are NOT auto-registered as top-level slash commands.** So that `/aim-init`, `/aim-add`, etc. can be triggered directly by users, `install.sh` symlinks `commands/*.md` into `~/.claude/commands/`.

```
~/.claude/commands/aim-add.md         ← symlink
    ↓ points to
~/.claude/skills/ai-memory/commands/aim-add.md   ← skill internal resource
    ↓ (if skill is symlinked) actually points to
<dev-repo>/commands/aim-add.md        ← real file
```

**Benefit**: Command docs are maintained in one place (dev repo) and take effect globally via symlinks. Changes to `commands/*.md` are immediately reflected everywhere — no manual sync needed.

**`/aim-uninit --global`** cleans up these symlinks (only removes those pointing to ai-memory, preserves user's other commands).

## Version

Current: `0.1.0` (MVP)

See CHANGELOG.md for version history. The Skill checks GitHub for updates on startup and prompts users when a new version is available.

## Design Principles

1. **Filesystem is the source of truth** — INDEX.yaml is a rebuildable cache
2. **Soft constraints over hard permissions** — Use confirmation instead of blocking
3. **Conservative compression** — Preserve rather than lose
4. **Rule-based validation** — Use regex to extract hard info, don't trust LLM self-checks
5. **Complete separation of Skill body and user data** — Uninstall preserves data

## Reference Docs

- `reference/upgrade-check.md` — Upgrade check mechanism (non-blocking, once daily)

> Additional reference docs (document lifecycle, compression pipeline details, mode comparison, soft sandbox, etc.) will be added in v0.2.

## License

MIT
