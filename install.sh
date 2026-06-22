#!/usr/bin/env bash
#
# ai-memory install script
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/shmxybfq/ai-memory/main/install.sh | bash
#
# Or clone first then run:
#   git clone https://github.com/shmxybfq/ai-memory /tmp/ai-memory && /tmp/ai-memory/install.sh
#
# This script will:
#   1. Clone (or update) ai-memory into ~/.claude/skills/ai-memory
#   2. Initialize ~/.claude/ai-memory/ for user data (identity, etc.)
#   3. Symlink commands/*.md into ~/.claude/commands/ so /aim-* commands are available
#   4. Print next-step instructions
#
# This script will NOT:
#   - Modify any existing CLAUDE.md
#   - Create any project-level files
#   - Send any telemetry data
#
# After installation, run /aim-init in any project to complete setup.

set -e

SKILL_DIR="${HOME}/.claude/skills/ai-memory"
DATA_DIR="${HOME}/.claude/ai-memory"
REPO_URL="https://github.com/shmxybfq/ai-memory"

# Output helper functions
info()    { printf "\033[34m[info]\033[0m  %s\n" "$*"; }
success() { printf "\033[32m[ok]\033[0m    %s\n" "$*"; }
warn()    { printf "\033[33m[warn]\033[0m  %s\n" "$*"; }
error()   { printf "\033[31m[err]\033[0m   %s\n" "$*" >&2; }
die()     { error "$*"; exit 1; }

# Pre-flight checks
command -v git >/dev/null 2>&1 || die "git is required. Please install it first."
[ -d "${HOME}/.claude" ] || mkdir -p "${HOME}/.claude"

info "Installing ai-memory..."

# Step 1: Install/update Skill
if [ -L "${SKILL_DIR}" ] || [ -d "${SKILL_DIR}/.git" ]; then
    info "Existing installation detected, updating..."
    if [ -L "${SKILL_DIR}" ]; then
        # Symlink — follow to real path and update there
        REAL_PATH=$(readlink "${SKILL_DIR}")
        info "Symlink detected, updating target: ${REAL_PATH}"
        if [ -d "${REAL_PATH}/.git" ]; then
            cd "${REAL_PATH}" && git pull --ff-only || warn "git pull failed, continuing"
        else
            warn "Symlink target is not a git repo, skipping update"
        fi
    else
        cd "${SKILL_DIR}" && git pull --ff-only || warn "git pull failed, continuing"
    fi
else
    info "Cloning from ${REPO_URL}..."
    mkdir -p "${HOME}/.claude/skills"
    git clone --depth 1 "${REPO_URL}" "${SKILL_DIR}" || die "git clone failed"
fi

# Step 2: Initialize data directory
mkdir -p "${DATA_DIR}"

# Step 2.5: Sync commands/ into ~/.claude/commands/ (symlinks)
# Why this is needed: Claude Code has two separate command systems —
#   - Skills: ~/.claude/skills/<name>/SKILL.md (triggered via /<skill-name>)
#   - Slash Commands: ~/.claude/commands/*.md (triggered via /<command-name>)
# Commands inside a Skill's commands/*.md are NOT automatically registered as top-level slash commands.
# They must be symlinked into ~/.claude/commands/ for /aim-init and friends to be directly invocable.
info "Syncing commands/ into ~/.claude/commands/ (symlinks)..."
mkdir -p "${HOME}/.claude/commands"
SYNC_COUNT=0
SKIP_COUNT=0
for cmd_file in "${SKILL_DIR}/commands/"*.md; do
    [ -f "$cmd_file" ] || continue
    cmd_name=$(basename "$cmd_file")
    link_path="${HOME}/.claude/commands/${cmd_name}"

    # Protect user-defined commands: if a real file (not symlink) already exists,
    # check whether it belongs to ai-memory by looking for "name: aim-" in frontmatter
    if [ -e "$link_path" ] && [ ! -L "$link_path" ]; then
        if grep -q "^name: aim-" "$link_path" 2>/dev/null; then
            # This is an old copy from ai-memory (possibly installed by an earlier version), safe to replace with symlink
            rm -f "$link_path"
        else
            # This is a user-defined command, leave it alone
            warn "Skipping ${cmd_name}: ~/.claude/commands/${cmd_name} is a user-defined command, not overwriting"
            SKIP_COUNT=$((SKIP_COUNT + 1))
            continue
        fi
    fi

    ln -sf "$cmd_file" "$link_path"
    SYNC_COUNT=$((SYNC_COUNT + 1))
done
info "Synced ${SYNC_COUNT} commands into ~/.claude/commands/"
if [ "$SKIP_COUNT" -gt 0 ]; then
    warn "${SKIP_COUNT} user-defined command(s) preserved (not overwritten)"
fi

# Write initial version cache (prevents "new version available" notification right after install)
SKILL_VERSION=$(grep -E '^version:' "${SKILL_DIR}/SKILL.md" 2>/dev/null | head -1 | sed 's/version: *//; s/[[:space:]]*$//')
[ -z "${SKILL_VERSION}" ] && SKILL_VERSION="0.1.0"

CACHE_FILE="${DATA_DIR}/last-version-check.json"
if [ ! -f "${CACHE_FILE}" ]; then
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    cat > "${CACHE_FILE}" <<EOF
{
  "checked_at": "${NOW}",
  "latest_version": "${SKILL_VERSION}",
  "current_version": "${SKILL_VERSION}",
  "release_url": "",
  "release_notes_excerpt": "",
  "user_dismissed": []
}
EOF
    info "Initialized version cache (current version: ${SKILL_VERSION})"
fi

# Step 3: Verify installation
if [ ! -f "${SKILL_DIR}/SKILL.md" ]; then
    die "Installation incomplete: SKILL.md not found at ${SKILL_DIR}/SKILL.md"
fi

# Done
echo ""
success "ai-memory ${SKILL_VERSION} installed!"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code (or start a new session)"
echo "  2. In any project, run: /aim-init <project-name>"
echo "  3. After accumulating 3-5 docs, run: /aim-compress"
echo ""
echo "Common commands:"
echo "  /aim-help     Show all commands"
echo "  /aim-list     List all ai-memory projects"
echo "  /aim-uninit   Remove from project (--global to uninstall the Skill itself)"
echo ""
echo "Documentation:"
echo "  ${SKILL_DIR}/README.md"
echo "  ${REPO_URL}"
echo ""
