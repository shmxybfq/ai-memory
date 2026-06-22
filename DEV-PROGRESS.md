# ai-memory Development Progress

> This document restores development state across sessions and after context compression. Claude should read this document first at the start of each new session.

**Last updated**: 2026-06-21 18:30
**Current stage**: MVP full-flow testing passed, core revisions complete. 10/10 tasks done.

---

## 1. Project Overview

**ai-memory** is a Claude Code Skill collection that provides cross-session project memory for Claude Code users.

- **GitHub**: https://github.com/shmxybfq/ai-memory
- **Local path**: `~/Desktop/ai-memory/`
- **Symlink**: `~/.claude/skills/ai-memory → ~/Desktop/ai-memory/` (live in development)
- **Design document**: `~/Desktop/persistent-document/bauto-video/2026-06-12-snapshot/ai-memory-open-source-design-discussion.html` (22 chapters)

---

## 2. User Information

| Item | Value |
|---|---|
| GitHub username | `shmxybfq` |
| Git user.name | Developer |
| Git user.email | [redacted] |
| Operating system | macOS Darwin 24.6.0 |

---

## 3. Key Conventions (Must Follow)

### 3.1 User Preferences
- **Command documents and user-facing text in English** (global audience)
- Do not over-engineer; ship the minimum viable version first
- Confirm as you go; major decisions via AskUserQuestion
- All documents in HTML format (not Markdown)

### 3.2 Design Decisions (Locked)
- **Form**: Pure Claude Code Skill only (no CLI, no MCP — deferred to future versions)
- **Default mode**: Centralized (following persistent-document conventions)
- **Distributed mode**: Project-embedded `.ai-memory/`
- **Document format**: HTML + header metadata comment (`<!-- aim:doc_id=... -->`)
- **INDEX.yaml**: Rebuildable cache, not the source of truth
- **Compressed document**: Single file, dual zone (active + archive), soft-delete (never hard-delete)
- **Verification mechanism**: Rule-based diff over LLM self-check (regex extraction of version numbers, filenames, commands, config values)
- **Cross-tool support**: Not in MVP

### 3.3 Collaboration Design (Soft Sandbox)
- **User identity**: Global `~/.claude/ai-memory/identity.json` (id format `u-<8 random chars>`)
- **Identity acquisition**: Prefer git config user.name, then ask
- **Soft sandbox**: Users can only directly operate on their own documents by default
- **Cross-sandbox**: Always ask, no caching, commit message tags `[cross-user:from <name>]`
- **Compressed document ownership**: `__project__` (not owned by individuals)
- **doc_id format**: `aim-YYYYMMDD-<6 random chars>`

### 3.4 Distribution Decisions (5 items confirmed)
1. GitHub repo: **Personal account** (shmxybfq)
2. `/aim-uninit`: **Provided**
3. `/aim-help`: **Ship in MVP**
4. Upgrade notification: **Ship in MVP**
5. README: **English primary + Chinese version**

### 3.5 Command Decisions
- Centralized default root directory: **Let user enter each time** (no preset default)
- Project subdirectory name: **Let user enter each time**
- CLAUDE.md injection location: **Root directory** (centralized) or project root (distributed)
- Identity ID generation: **`u-<8 random chars>`**

---

## 4. File Structure (Current State)

```
~/Desktop/ai-memory/
├── SKILL.md                              ✅ Skill entry point (14-command manifest)
├── DEV-PROGRESS.md                       ✅ This document
├── README.md                             ✅ English primary docs
├── README.zh-CN.md                       ✅ Chinese docs
├── CHANGELOG.md                          ✅ Version history
├── install.sh                            ✅ One-line install script (executable)
├── .gitignore                            ✅
├── commands/                             ✅ All 14 commands
│   ├── aim-init.md                       ✅
│   ├── aim-add.md                        ✅
│   ├── aim-append.md                     ✅
│   ├── aim-edit.md                       ✅
│   ├── aim-archive.md                    ✅
│   ├── aim-compress.md                   ✅ MVP simplified version
│   ├── aim-status.md                     ✅
│   ├── aim-rebuild.md                    ✅
│   ├── aim-verify.md                     ✅
│   ├── aim-expand.md                     ✅
│   ├── aim-list.md                       ✅
│   ├── aim-help.md                       ✅
│   ├── aim-identity.md                   ✅
│   └── aim-uninit.md                     ✅
├── prompts/                              Empty (three-stage pipeline deferred to v0.2)
├── templates/                            ✅
│   ├── INDEX.yaml.tpl                    ✅
│   ├── claude-md-rules.md.tpl            ✅
│   ├── doc-template.html.tpl             ✅
│   └── compressed-template.html.tpl      ✅
└── reference/                            ✅
    └── upgrade-check.md                  ✅
```

---

## 5. Task Progress

### Completed
- ✅ #1 Create project skeleton
- ✅ #2 Connect GitHub repo and first push (commit `2079b12`)
- ✅ #3 Develop `/aim-init`
- ✅ #4 Develop `/aim-add`
- ✅ #5 Develop `/aim-status` (token estimation, Git diff behind warning, health tips)
- ✅ #6 Develop `/aim-rebuild` + `/aim-verify`
- ✅ #7 Develop `/aim-compress` (MVP simplified version)
- ✅ #8 Auxiliary commands: `/aim-help` `/aim-list` `/aim-expand` `/aim-uninit` `/aim-identity` + upgrade notification
- ✅ #8 Complete remaining: `/aim-append` `/aim-edit` `/aim-archive` (listed in SKILL.md but not yet written)
- ✅ #9 Write README.md (English) + README.zh-CN.md (Chinese) + install.sh + CHANGELOG

### TODO
- ✅ #10 Real project validation and prompt tuning (completed 2026-06-21)
  - Test directory: `~/Desktop/ai-memory-test/` (created, can keep for regression testing)
  - Full flow: `init → add×3 → status → compress → expand → rebuild → verify`
  - Found 5 issues and applied fixes (see Section 11)

### Near-Term Candidates (post 2026-06-21, priority-ordered)

#### Candidate 1: Real test of `/aim-init` (High priority)
- **Purpose**: Fill "Gap 1: no real LLM validation." All previous tests had Claude role-playing the LLM flow, not a real third-party validation.
- **Trigger**: After command registration fix (commit 47e7310), `/aim-*` is now available in real Claude Code.
- **How**: Run `/aim-init` → `/aim-add` ×3 → `/aim-compress` in an independent test directory, observe whether constraints truly take effect.
- **Expected outcome**: Reveal where constraints break down, allowing targeted reinforcement.

#### Candidate 2: Write a public-facing article (Medium priority)
- **Topic**: "The Two Command System Trap in Claude Code Skill Development" (or similar)
- **Source material**: Diagnosis + solution + lessons from the 3rd conversation sync
- **Channels**: Blog / Twitter / Zhihu / Xiaohongshu (user preference TBD)
- **Value**: Help other Skill developers avoid the same pitfall; also drives users to ai-memory.
- **Alternative**: Write a `LESSONS.md` or `docs/` article in the ai-memory repo, but not in `reference/` (over-engineered, nobody reads it).

#### Candidate 3: Push v0.2 migration tool (Medium priority)
- **Purpose**: Fill "Gap 2: user can't actually use it (persistent-document incompatible)"
- **Work**: Write an `aim-migrate` command to upgrade persistent-document simplified INDEX.yaml format to full ai-memory format
- **Challenges**:
  - Backfill `<!-- aim:... -->` metadata headers into existing HTML documents
  - Handle Chinese snapshot directory names → English format (optionally keep Chinese)
  - Decision: overwrite original persistent-document or save separately after migration
- **Value**: Let users actually use ai-memory for their core scenario (managing persistent-document)

---

## 11. Test Findings and Revisions (2026-06-21)

### Test Coverage
| Command | Test Result |
|---|---|
| `/aim-init` | ✅ Identity creation, mode selection, directory structure, INDEX/CLAUDE.md injection |
| `/aim-add x3` | ✅ HTML template rendering, metadata embedding, INDEX active list update |
| `/aim-status` | ✅ Document stats, token estimation, compression suggestion thresholds |
| `/aim-compress` | ✅ Dual-zone output, source attribution, rule verification, appendix append |
| `/aim-expand` | ✅ Topic filtering, cross-snapshot search |
| `/aim-rebuild` | ✅ Full rebuild from corrupted INDEX, orphan file detection |
| `/aim-verify` | ✅ MISSING_FILE/META_MISSING/ORPHAN checks |

### Issues Found and Fixes

#### Issue 1: Template conditional block syntax inconsistency (Fixed)
- `claude-md-rules.md.tpl` used `{{#CENTRAL}}...{{/CENTRAL}}` Mustache conditionals, while other templates used simple `{{KEY}}` placeholders.
- **Fix**: Added explicit handling rules in `aim-init.md` Step 8 (central mode keeps inline, distributed mode removes the entire block).

#### Issue 2: Rule verification case-sensitivity mismatch (Fixed)
- `Modal` (original document) vs `modal` (compressed document) was flagged as missing.
- **Fix**: Added case-sensitivity rules in `aim-compress.md` Step 7: code identifiers are case-sensitive, natural language words are not.

#### Issue 3: Compressed document sources unrecoverable by rebuild (Fixed)
- The source doc_id list for compressed documents was only in INDEX, not in the file's metadata header.
- **Fix**: Added `sources={{SOURCES}}` field to `compressed-template.html.tpl` metadata header; added sources to `aim-compress.md` Step 6 output notes; added sources recovery logic in `aim-rebuild.md` Step 5 (backward-compatible with old documents).

#### Issue 4: No guidance when CLAUDE.md is a symlink (Fixed)
- **Fix**: Added symlink handling to `aim-init.md` Step 8 item 5 (write to target, don't break the link).

#### Issue 5: Test identity pollution (Pending cleanup)
- Testing created `u-r00hpf42` Zhu Taofeng in `~/.claude/ai-memory/identity.json`.
- Real usage will reuse this identity (since it's global).
- **Recommendation**: User decides whether to clean up (delete entire `~/.claude/ai-memory/` directory if test identity is unwanted).

### Untested Items (deferred)
- Cross-user soft sandbox confirmation flow (single-person testing can't cover this)
- Git integration commit/push (test directory is not in a git repo)
- Upgrade notification mechanism (requires a GitHub release)
- Real LLM executing commands (this test had Claude role-play the LLM flow)
- macOS Trash move (`--purge` path)

---

## 6. Key Command Design Points

### `/aim-init` Flow
1. Resolve user identity (read identity.json or create new)
2. Ask for storage mode (centralized default 1)
3. Ask for root directory (no default, let user enter)
4. Ask for project name and subdirectory name
5. Check if already initialized
6. Create directories, generate INDEX.yaml, inject CLAUDE.md (append, don't overwrite)
7. Optional Git initialization
8. Output results

### `/aim-add` Flow
1. Resolve current project (read INDEX.yaml)
2. Resolve user identity
3. Collect content (from parameters or by asking)
4. Metadata: title/source/tags/filename/doc_id
5. Generate HTML (using template)
6. Write file
7. Update INDEX.yaml active list (including contributors, tokens)
8. Optional git commit
9. Output results + compression suggestion (3+/5+/8+ three-tier prompts)

### `/aim-compress` MVP Flow
1. Select source documents (default: all active)
2. Read full text of all source documents
3. Check for existing compressed document (incremental merge vs fresh)
4. **Single-pass LLM merge** (not three-stage):
   - 7 fixed chapter output
   - Merge same-topic content; conflicting content: new supersedes old, old goes to archive zone
   - Source attribution `[Source: document title @ author]`
5. Rule verification (regex extraction of hard info: version numbers, paths, commands, configs)
6. Write to `compressed-YYYYMMDD.html`
7. **Move** (not copy) source documents to snapshots
8. Update INDEX.yaml: clear active, set compressed, record snapshots
9. Optional git commit

### Soft Sandbox Rules
- `/aim-add` always creates new files, owner = current user
- `/aim-append` `/aim-edit` `/aim-archive` require confirmation for cross-user operations
- Compressed document cross-user operations require confirmation (`__project__` is shared)
- Public commands (`/aim-status` `/aim-rebuild` `/aim-verify` `/aim-expand` `/aim-list` `/aim-help` `/aim-identity` `/aim-uninit`) are exempt from sandbox constraints

### Commit Message Convention
- `[aim-init] <project-name> - Initialize project memory (<username>)`
- `[aim-add] <project-name> - Created <filename> (doc:<doc_id>)`
- `[aim-edit] <project-name> - Edited <filename> [cross-user:from <original-owner>] (doc:<doc_id>)`
- `[aim-compress] <project-name> - <date> compression archive (merged N docs)`

---

## 7. MVP Must-Have Checklist (11 items)

1. ✅ GitHub repo public
2. ✅ install.sh one-line script (executable, with version cache initialization)
3. ✅ Git clone installation (supported)
4. ✅ README.md (English primary) + README.zh-CN.md (Chinese version)
5. ⏳ 5-minute quickstart guide (pending, or merge into README)
6. ✅ Command manifest (SKILL.md lists all 14)
7. ✅ CHANGELOG
8. ✅ GitHub Issues enabled (GitHub default)
9. ✅ `/aim-uninit` uninstall command
10. ✅ `/aim-help` built-in help
11. ✅ Upgrade notification mechanism (reference/upgrade-check.md)

### MVP Will NOT Do
- ❌ Plugin Marketplace release
- ❌ Video/blog promotion
- ❌ Discord community
- ❌ Three-stage compression pipeline (v0.2)
- ❌ MCP integration (v0.3)
- ❌ GUI

---

## 8. Key Technical Details

### Metadata Header Format (HTML Comment)
```html
<!-- aim:doc_id=aim-20260621-a3b2f1 title=Auth Module Design tags=auth,security created=2026-06-21 created_by=u-a3b2f1c9 owner=u-a3b2f1c9 status=active source=conversation version=1 -->
```

### INDEX.yaml Structure
```yaml
project: "Video Project"
mode: "central"
root: "/abs/path"
updated: "2026-06-21"

compressed: []        # Single file, owner=__project__

active:
  - doc_id: "..."
    title: "..."
    file: "..."
    owner: "u-xxx"
    owner_name: "..."
    created: "..."
    created_by: "..."
    updated: "..."
    last_modified_by: "..."
    version: 1
    status: "active"
    source: "..."
    tags: [...]
    permission: "private"
    tokens: 1200
    contributors:
      - { user: "u-xxx", name: "...", last: "..." }

snapshots:
  - date: "2026-06-21"
    reason: "compressed / pre-edit-backup / manual"
    files: [...]
    compressed_into: "..." # Only for compressed type
    archived_from: "..."   # Only for archived type
```

### Token Estimation (Rough)
- CJK: 1 character ≈ 1 token
- English: 4 characters ≈ 1 token
- HTML tag overhead ≈ 50%
- Simplified formula: file_size_bytes / 3.5

### Compression Suggestion Thresholds
- 3+ active docs → gentle prompt
- 5+ active docs → strong suggestion
- 8+ active docs → warning (bloat risk)

### Upgrade Notification Mechanism
- `~/.claude/ai-memory/last-version-check.json` caches check results
- Checks once every 24 hours
- Same version never re-notifies (user_dismissed array)
- Offline: silently skip, no errors
- `~/.claude/ai-memory/no-auto-check` file existence disables checks entirely

---

## 9. How to Continue Development

### New Session / Post-Compression Recovery Flow
1. Read `~/Desktop/ai-memory/DEV-PROGRESS.md` (this document)
2. Read latest task state (`TaskList` or Section 5 of this document)
3. Use `TaskUpdate` to mark the relevant task as in_progress
4. Continue as needed:
   - Write the next `commands/<name>.md`
   - Or run real project tests under `~/Desktop/persistent-document/`
   - Or tune existing command docs

### Template for Writing Command Docs
- Frontmatter: `name` + `description`
- Sections: Purpose / Usage / Prerequisites / Flow / Edge Cases / Output Style / Reference
- English throughout
- Emojis: ✅ ❌ ⚠️ 📋 📁 📝 💡 📊 🔍 🗜️ 🚨

---

## 10. Important Notes

1. **Do not modify git config** (user preference)
2. **Proxy must use socks5h** (not socks5 — the former does remote DNS)
3. **HTTPS push requires a PAT** — never let users paste their PAT into conversation (have them push in their own terminal)
4. **CLAUDE.md injection uses append** — never overwrite existing user content
5. **Never delete files** — only move to snapshots/ or Trash
6. **doc_id is immutable once generated** (even if the file is renamed)
7. **Don't pollute `~/Desktop/persistent-document/` during testing** — create an independent test directory or ask explicitly
8. **PAT exposure incident: handled by user (revoked)**

---

**After context compression, just say "continue development" and I will read this document to restore state.**
