#!/usr/bin/env bash
#
# ai-memory install script
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/shmxybfq/ai-memory/main/install.sh | bash
#
# Or clone first:
#   git clone https://github.com/shmxybfq/ai-memory /tmp/ai-memory && /tmp/ai-memory/install.sh
#
# What it does:
#   1. Clones (or updates) ai-memory to ~/.claude/skills/ai-memory
#   2. Initializes ~/.claude/ai-memory/ for user data (identity, etc.)
#   3. Prints next-step instructions
#
# What it does NOT do:
#   - Modify any existing CLAUDE.md
#   - Create any project-level files
#   - Send any telemetry
#
# After install, run /aim-init inside any project to set it up.

set -e

SKILL_DIR="${HOME}/.claude/skills/ai-memory"
DATA_DIR="${HOME}/.claude/ai-memory"
REPO_URL="https://github.com/shmxybfq/ai-memory"

# Print helpers
info()    { printf "\033[34m[info]\033[0m  %s\n" "$*"; }
success() { printf "\033[32m[ok]\033[0m    %s\n" "$*"; }
warn()    { printf "\033[33m[warn]\033[0m  %s\n" "$*"; }
error()   { printf "\033[31m[err]\033[0m   %s\n" "$*" >&2; }
die()     { error "$*"; exit 1; }

# Pre-flight checks
command -v git >/dev/null 2>&1 || die "git is required. Install it first."
[ -d "${HOME}/.claude" ] || mkdir -p "${HOME}/.claude"

info "Installing ai-memory..."

# Step 1: Install/Update Skill
if [ -L "${SKILL_DIR}" ] || [ -d "${SKILL_DIR}/.git" ]; then
    info "Existing installation detected, updating..."
    if [ -L "${SKILL_DIR}" ]; then
        # Symlink — follow it to the real path and update there
        REAL_PATH=$(readlink "${SKILL_DIR}")
        info "Symlink detected, updating target: ${REAL_PATH}"
        if [ -d "${REAL_PATH}/.git" ]; then
            cd "${REAL_PATH}" && git pull --ff-only || warn "git pull failed, will continue"
        else
            warn "Symlink target is not a git repo, skipping update"
        fi
    else
        cd "${SKILL_DIR}" && git pull --ff-only || warn "git pull failed, will continue"
    fi
else
    info "Cloning from ${REPO_URL}..."
    mkdir -p "${HOME}/.claude/skills"
    git clone --depth 1 "${REPO_URL}" "${SKILL_DIR}" || die "git clone failed"
fi

# Step 2: Initialize data directory
mkdir -p "${DATA_DIR}"

# Write initial version cache (prevents immediate "new version available" prompt)
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
    info "Initialized version cache (current: ${SKILL_VERSION})"
fi

# Step 3: Verify install
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
echo "  3. After 3-5 docs, run: /aim-compress"
echo ""
echo "Useful commands:"
echo "  /aim-help     Show all commands"
echo "  /aim-list     List all projects with ai-memory"
echo "  /aim-uninit   Remove from a project (--global to uninstall)"
echo ""
echo "Documentation:"
echo "  ${SKILL_DIR}/README.md"
echo "  ${REPO_URL}"
echo ""
