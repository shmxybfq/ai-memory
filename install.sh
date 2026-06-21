#!/usr/bin/env bash
#
# ai-memory 安装脚本
#
# 用法:
#   curl -fsSL https://raw.githubusercontent.com/shmxybfq/ai-memory/main/install.sh | bash
#
# 或先 clone 再运行:
#   git clone https://github.com/shmxybfq/ai-memory /tmp/ai-memory && /tmp/ai-memory/install.sh
#
# 本脚本会做:
#   1. 把 ai-memory 克隆(或更新)到 ~/.claude/skills/ai-memory
#   2. 初始化 ~/.claude/ai-memory/ 用于存放用户数据(identity 等)
#   3. 把 commands/*.md 软链接到 ~/.claude/commands/,让 /aim-* 命令可用
#   4. 打印下一步操作指引
#
# 本脚本不会做:
#   - 修改任何已存在的 CLAUDE.md
#   - 创建任何项目级文件
#   - 发送任何遥测数据
#
# 安装完成后,在任意项目中运行 /aim-init 完成初始化。

set -e

SKILL_DIR="${HOME}/.claude/skills/ai-memory"
DATA_DIR="${HOME}/.claude/ai-memory"
REPO_URL="https://github.com/shmxybfq/ai-memory"

# 输出辅助函数
info()    { printf "\033[34m[info]\033[0m  %s\n" "$*"; }
success() { printf "\033[32m[ok]\033[0m    %s\n" "$*"; }
warn()    { printf "\033[33m[warn]\033[0m  %s\n" "$*"; }
error()   { printf "\033[31m[err]\033[0m   %s\n" "$*" >&2; }
die()     { error "$*"; exit 1; }

# 预检查
command -v git >/dev/null 2>&1 || die "需要 git,请先安装。"
[ -d "${HOME}/.claude" ] || mkdir -p "${HOME}/.claude"

info "正在安装 ai-memory..."

# 步骤 1:安装/更新 Skill
if [ -L "${SKILL_DIR}" ] || [ -d "${SKILL_DIR}/.git" ]; then
    info "检测到已有安装,执行更新..."
    if [ -L "${SKILL_DIR}" ]; then
        # 符号链接 — 跟踪到真实路径并在那里更新
        REAL_PATH=$(readlink "${SKILL_DIR}")
        info "检测到符号链接,更新目标: ${REAL_PATH}"
        if [ -d "${REAL_PATH}/.git" ]; then
            cd "${REAL_PATH}" && git pull --ff-only || warn "git pull 失败,继续执行"
        else
            warn "符号链接目标不是 git 仓库,跳过更新"
        fi
    else
        cd "${SKILL_DIR}" && git pull --ff-only || warn "git pull 失败,继续执行"
    fi
else
    info "从 ${REPO_URL} 克隆..."
    mkdir -p "${HOME}/.claude/skills"
    git clone --depth 1 "${REPO_URL}" "${SKILL_DIR}" || die "git clone 失败"
fi

# 步骤 2:初始化数据目录
mkdir -p "${DATA_DIR}"

# 步骤 2.5:同步 commands/ 到 ~/.claude/commands/(软链接)
# 必要性:Claude Code 的两套命令系统是分开的 ——
#   - Skills:~/.claude/skills/<name>/SKILL.md(通过 /<skill-name> 触发)
#   - Slash Commands:~/.claude/commands/*.md(通过 /<command-name> 触发)
# Skill 内部的 commands/*.md 不会被自动注册为顶层 slash command。
# 必须把它们软链接到 ~/.claude/commands/,/aim-init 等命令才能被用户直接调用。
info "同步 commands/ 到 ~/.claude/commands/(软链接)..."
mkdir -p "${HOME}/.claude/commands"
SYNC_COUNT=0
SKIP_COUNT=0
for cmd_file in "${SKILL_DIR}/commands/"*.md; do
    [ -f "$cmd_file" ] || continue
    cmd_name=$(basename "$cmd_file")
    link_path="${HOME}/.claude/commands/${cmd_name}"

    # 保护用户自定义命令:如果已存在真实文件(非 symlink),检查它是否是 ai-memory 的
    # 通过判断文件 frontmatter 是否包含 "name: aim-" 来识别
    if [ -e "$link_path" ] && [ ! -L "$link_path" ]; then
        if grep -q "^name: aim-" "$link_path" 2>/dev/null; then
            # 是 ai-memory 的旧复制品(可能是早期版本安装的),可以替换为软链接
            rm -f "$link_path"
        else
            # 是用户自定义命令,保留不动
            warn "跳过 ${cmd_name}:~/.claude/commands/${cmd_name} 是用户自定义命令,不覆盖"
            SKIP_COUNT=$((SKIP_COUNT + 1))
            continue
        fi
    fi

    ln -sf "$cmd_file" "$link_path"
    SYNC_COUNT=$((SYNC_COUNT + 1))
done
info "已同步 ${SYNC_COUNT} 个命令到 ~/.claude/commands/"
if [ "$SKIP_COUNT" -gt 0 ]; then
    warn "${SKIP_COUNT} 个用户自定义命令被保留(未覆盖)"
fi

# 写入初始版本缓存(避免安装后立即提示"有新版本")
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
    info "已初始化版本缓存(当前版本: ${SKILL_VERSION})"
fi

# 步骤 3:验证安装
if [ ! -f "${SKILL_DIR}/SKILL.md" ]; then
    die "安装不完整:在 ${SKILL_DIR}/SKILL.md 找不到 SKILL.md"
fi

# 完成
echo ""
success "ai-memory ${SKILL_VERSION} 已安装!"
echo ""
echo "下一步:"
echo "  1. 重启 Claude Code(或开启新会话)"
echo "  2. 在任意项目中运行: /aim-init <项目名>"
echo "  3. 攒到 3-5 篇文档后运行: /aim-compress"
echo ""
echo "常用命令:"
echo "  /aim-help     显示所有命令"
echo "  /aim-list     列出所有 ai-memory 项目"
echo "  /aim-uninit   从项目中移除(--global 卸载 Skill 本体)"
echo ""
echo "文档:"
echo "  ${SKILL_DIR}/README.md"
echo "  ${REPO_URL}"
echo ""
