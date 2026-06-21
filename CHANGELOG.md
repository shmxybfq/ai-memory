# Changelog

All notable changes to ai-memory are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.0] — 2026-06-21 (MVP)

### Added

- **Core command set (14 commands):**
  - `/aim-init` — Initialize project memory (central or distributed mode)
  - `/aim-add` — Add new document with metadata embedding
  - `/aim-append` — Append section to existing document
  - `/aim-edit` — Modify existing document (with snapshot backup)
  - `/aim-archive` — Move document to snapshots
  - `/aim-compress` — Merge active docs into dual-zone compressed file (MVP single-pass)
  - `/aim-status` — Show project state, token usage, Git drift
  - `/aim-verify` — Consistency check between INDEX and filesystem
  - `/aim-rebuild` — Rebuild INDEX.yaml from filesystem
  - `/aim-expand` — Reverse-search snapshots for original detail
  - `/aim-list` — List all projects with ai-memory
  - `/aim-help` — Built-in command catalog
  - `/aim-identity` — View/modify global user identity
  - `/aim-uninit` — Remove Skill injections (project or global)

- **Storage modes:**
  - Central mode: all projects under one root, shared CLAUDE.md
  - Distributed mode: per-project `.ai-memory/` directory

- **Soft sandbox:**
  - Global user identity at `~/.claude/ai-memory/identity.json`
  - Cross-user operation confirmation (no caching, every time)
  - Public commands (status, verify, rebuild, list, expand, help) bypass sandbox

- **Document model:**
  - HTML format with embedded metadata in HTML comments
  - Filesystem is source of truth; INDEX.yaml is rebuildable cache
  - Snapshot-based history (never delete, always move)
  - Token estimation (Chinese ~1 char/token, English ~4 chars/token)

- **Compression (MVP):**
  - Dual-zone output: active zone (7 fixed sections) + archive zone
  - Source attribution preserved
  - Rule-based verification on hard info (versions, paths, commands, configs)
  - Incremental merge with existing compressed doc

- **Operational safety:**
  - All destructive operations go through macOS Trash (recoverable)
  - Automatic backups before INDEX.yaml modifications
  - CLAUDE.md rules appended (never overwrite user content)
  - Rule markers (`<!-- ai-memory rules start/end -->`) for clean removal

- **Distribution:**
  - `install.sh` one-line installer
  - GitHub clone installation supported
  - English (primary) + Chinese (secondary) README
  - Auto version check (once per day, non-blocking, disable-able)

### Design Principles Established

1. Filesystem is source of truth
2. Soft constraints over hard permissions
3. Conservative compression (better keep than lose)
4. Rule-based verification (don't trust LLM self-check)
5. Skill body and user data completely separated

### Limitations (deferred to later versions)

- Single-pass compression (no three-stage analyze → merge → verify pipeline)
- No MCP integration (Claude Code only)
- No multi-language UI (Chinese default, English docs only)
- No automatic scheduling (all commands user-triggered)
- No GUI

## Roadmap

### v0.2.0 — Compression Pipeline Upgrade
- Three-stage compression pipeline (analyze → merge → verify with retry loop)
- Section-level quality scoring
- Automatic "should split into multiple compressions" detection
- Iterative refinement when verification fails

### v0.3.0 — Cross-Tool Support
- MCP server implementation
- Cursor / Windsurf / Continue integration
- Standardized document schema for tool-agnostic access

### v0.4.0 — Collaboration Enhancements
- Team identity sync (shared user directory)
- Pull-request style review for cross-user edits
- Conflict resolution helpers
- Optional trust caching (per-pair, with expiry)

### v0.5.0 — Productivity
- Auto-summarization on doc-create (Claude drafts, user approves)
- Smart dedup detection across active docs
- Tag-based exploration view
- Search across all projects

### v1.0.0 — General Availability
- Stable file format (frozen, future versions backward-compatible)
- Comprehensive test suite
- Multi-platform installers (macOS, Linux, WSL)
- Performance benchmarks published

---

Older history: project started 2026-06-15, MVP development 2026-06-15 → 2026-06-21.
