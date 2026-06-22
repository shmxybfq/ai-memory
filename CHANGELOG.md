# Changelog

All notable changes to ai-memory are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- Translated all command documents, SKILL.md, templates, install.sh, CHANGELOG, and DEV-PROGRESS from Chinese back to English for global audience accessibility. README.zh-CN.md preserved as Chinese version. All functional content (6-layer quality framework, command registration mechanism, etc.) retained.

## [0.1.0] — 2026-06-21 (MVP)

### Added

- **Core command set (14 commands):**
  - `/aim-init` — Initialize project memory (centralized or distributed mode)
  - `/aim-add` — Add a new document (with embedded metadata)
  - `/aim-append` — Append sections to an existing document
  - `/aim-edit` — Edit an existing document (auto snapshot backup)
  - `/aim-archive` — Move a document into a snapshot
  - `/aim-compress` — Merge active documents into a dual-zone compressed file (MVP single-pass)
  - `/aim-status` — Show project status, token usage, Git drift
  - `/aim-verify` — Check INDEX vs filesystem consistency
  - `/aim-rebuild` — Rebuild INDEX.yaml from the filesystem
  - `/aim-expand` — Reverse-search snapshots for original details
  - `/aim-list` — List all ai-memory projects
  - `/aim-help` — Built-in command directory
  - `/aim-identity` — View/modify global user identity
  - `/aim-uninit` — Remove Skill injection (project-level or global)

- **Storage modes:**
  - Centralized mode: all projects under a single root directory, sharing one CLAUDE.md
  - Distributed mode: each project has its own embedded `.ai-memory/` directory

- **Soft sandbox:**
  - Global user identity stored in `~/.claude/ai-memory/identity.json`
  - Cross-user operations require explicit confirmation (no caching, always ask)
  - Public commands (status, verify, rebuild, list, expand, help) bypass the sandbox

- **Document model:**
  - HTML format with metadata embedded in HTML comments
  - Filesystem is the source of truth; INDEX.yaml is a rebuildable cache
  - Snapshot-based history (never delete, only move)
  - Token estimation (~1 char/token for CJK, ~4 chars/token for English)

- **Compression (MVP):**
  - Dual-zone output: active section (7 fixed chapters) + archive section
  - Source attribution preserved
  - Rule-based hard-info verification (version numbers, paths, commands, configs)
  - Incremental merge with existing compressed documents

- **Operational safety:**
  - All destructive operations go through macOS Trash (recoverable)
  - Automatic INDEX.yaml backup before modification
  - CLAUDE.md rule appending (never overwrites user content)
  - Rule markers (`<!-- ai-memory rules start/end -->`) for clean removal

- **Distribution:**
  - `install.sh` one-line installer
  - Git clone installation support
  - English (primary) + Chinese README
  - Automatic version checking (once daily, non-blocking, disableable)

### Established Design Principles

1. Filesystem is the source of truth
2. Soft constraints over hard permissions
3. Conservative compression (keep rather than lose)
4. Rule-based verification (don't trust LLM self-checks)
5. Complete separation of Skill code and user data

### Limitations (deferred to future versions)

- Single-pass compression (no three-stage "analyze → merge → verify" pipeline)
- No MCP integration (Claude Code only)
- No multi-language UI (English only; Chinese README available as README.zh-CN.md)
- No automatic scheduling (all commands triggered by user)
- No GUI

## Roadmap

### v0.2.0 — Compression Pipeline Upgrade
- Three-stage compression pipeline (analyze → merge → verify, with retry loop)
- Chapter-level quality scoring
- Automatic detection of scenarios that should be split into multiple compression passes
- Iterative refinement on verification failure

### v0.3.0 — Cross-Tool Support
- MCP server implementation
- Cursor / Windsurf / Continue integration
- Standardized document schema for tool-agnostic access

### v0.4.0 — Collaboration Enhancements
- Team identity sync (shared user directory)
- Pull Request-style review for cross-user edits
- Conflict resolution assistance
- Optional trust cache (per user pair, with expiration)

### v0.5.0 — Productivity
- Auto-summaries on document creation (Claude drafts, user confirms)
- Smart deduplication detection across active documents
- Tag-based exploration view
- Search across all projects

### v1.0.0 — General Availability
- Stable file format (frozen, backward-compatible in subsequent versions)
- Complete test suite
- Multi-platform installers (macOS, Linux, WSL)
- Published performance benchmarks

---

Earlier history: Project started 2026-06-15, MVP development cycle 2026-06-15 → 2026-06-21.
