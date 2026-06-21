---
name: ai-memory
description: Cross-session project memory layer for Claude Code. Provides document sedimentation, compression, archiving, and retrieval capabilities. Install once, gain persistent project knowledge across sessions.
version: 0.1.0
author: ai-memory
license: MIT
---

# ai-memory

> Cross-session memory layer for AI coding assistants — every new session, AI doesn't need to rediscover your project, it reads your accumulated project knowledge directly.

## What This Skill Does

`ai-memory` gives Claude Code persistent project memory across sessions. Instead of rediscovering the project each time, Claude reads your accumulated knowledge directly.

**Core capabilities:**
- 📝 Document sedimentation (`/aim-add`)
- 🗜️ Smart compression with 3-stage pipeline (`/aim-compress`)
- 📊 Status monitoring (`/aim-status`)
- 🔍 Reverse retrieval from snapshots (`/aim-expand`)
- 👥 Multi-user collaboration with soft sandbox
- 🧹 Auto-rebuild and verification

## Commands

| Command | Purpose | Sandbox |
|---|---|---|
| `/aim-init` | Initialize project memory (one-time) | ❌ |
| `/aim-add` | Add new document (always creates new file) | ✅ |
| `/aim-append` | Append section to existing document | ✅ |
| `/aim-edit` | Modify existing document | ✅ |
| `/aim-archive` | Archive document to snapshots | ✅ |
| `/aim-compress` | Compress active docs into single file (3-stage pipeline) | ⚠️ special |
| `/aim-status` | Show project status, token usage, Git drift | ❌ |
| `/aim-rebuild` | Rebuild INDEX.yaml from filesystem | ❌ |
| `/aim-verify` | Check INDEX.yaml vs filesystem consistency | ❌ |
| `/aim-expand` | Reverse-search snapshots for detail | ❌ |
| `/aim-list` | List all projects with ai-memory | ❌ |
| `/aim-help` | Show help for all commands | ❌ |
| `/aim-uninit` | Remove Skill injections (keep user data) | ❌ |
| `/aim-identity` | View or modify user identity | ❌ |

See `commands/` directory for each command's detailed flow.

## Core Concepts

### Two Storage Modes

- **Central mode (default)**: All projects share one document root (e.g., `~/Desktop/persistent-document/`). One CLAUDE.md manages all projects. Best for individuals managing multiple private projects.
- **Distributed mode**: Each project embeds `.ai-memory/` inside its codebase. Best for team collaboration and open source.

### Soft Sandbox (Multi-user Collaboration)

Each user has a global identity (`~/.claude/ai-memory/identity.json`). By default, users can only directly modify their own documents. Cross-user operations require explicit confirmation **every time** (no caching).

### Document Lifecycle

```
/aim-add  →  memory/*.html  →  /aim-compress  →  snapshots/YYYY-MM-DD/
                                  ↓
                          compressed.html
                  (dual-zone: active + archive)
```

### Dual-Zone Compression

The compressed document has two fixed zones:
- **Active zone**: Current valid knowledge (AI reads this first)
- **Archive zone**: Deprecated content marked `[deprecated]` (soft delete, not removed)

This prevents bloat without losing information.

### Metadata Embedding

Each document has metadata in HTML comments at the top:
```html
<!-- aim:doc_id=aim-20260610-a3b2f1 title=... tags=... created=... created_by=... owner=... status=... -->
```

INDEX.yaml is a **rebuildable cache**, not the source of truth. The filesystem is the source of truth.

## Usage Flow

### First Time
```
1. /aim-init [project-name]
   → Choose mode (central/distributed)
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
/aim-status    → Check state (occasionally)
/aim-compress  → Compress when 3-5 docs accumulated
```

## Architecture

```
ai-memory/
├── SKILL.md                  ← This file (entry point)
├── commands/                 ← One .md per slash command
├── prompts/                  ← Reusable Prompt templates (3-stage pipeline)
│   ├── 01-analyze.md
│   ├── 02-merge.md
│   ├── 03-verify.md
│   └── shared-rules.md
├── templates/                ← File templates
│   ├── INDEX.yaml.tpl
│   ├── claude-md-rules.md.tpl
│   ├── doc-template.html.tpl
│   └── compressed-template.html.tpl
└── reference/                ← Internal reference docs
```

## Version

Current: `0.1.0` (MVP)

See CHANGELOG.md for version history. The Skill checks GitHub for newer versions on startup and prompts the user if an update is available.

## Design Principles

1. **Filesystem is source of truth** — INDEX.yaml is rebuildable cache
2. **Soft constraints over hard permissions** — confirmation, not blocking
3. **Conservative compression** — better to keep than to lose
4. **Rule-based verification** — regex extract hard info, don't trust LLM self-check
5. **Skill body and user data completely separated** — uninstall keeps data

## Reference Documents

- `reference/document-lifecycle.md` — Document state transitions
- `reference/three-stage-pipeline.md` — Compression pipeline details
- `reference/rule-diff-verification.md` — How hard info verification works
- `reference/central-vs-distributed.md` — Mode comparison
- `reference/soft-sandbox.md` — Collaboration model

## License

MIT
