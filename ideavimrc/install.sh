#!/usr/bin/env bash
# IdeaVim 配置安装脚本
# 支持 macOS、Linux、Windows（Git Bash）
# 将仓库 ideavimrc/.ideavimrc 部署到 ~/.ideavimrc

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="${SCRIPT_DIR}/.ideavimrc"

: "${IDEAVIM_DRY_RUN:=}"
: "${IDEAVIM_USE_COPY:=}"
: "${IDEAVIM_SKIP_BACKUP:=}"

log_info() { printf '[INFO] %s\n' "$*"; }
log_ok() { printf '[OK] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }
die() { printf '[ERROR] %s\n' "$1" >&2; exit "${2:-1}"; }

run_with_timeout() {
    local seconds="$1"
    shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "${seconds}" "$@"
    else
        "$@"
    fi
}

OS="$(uname -s)"
if [[ "${OS}" == "Darwin" ]]; then
    PLATFORM="macos"
elif [[ "${OS}" == "Linux" ]]; then
    PLATFORM="linux"
elif [[ "${OS}" == MINGW* ]] || [[ "${OS}" == MSYS* ]] || [[ "${OS}" == CYGWIN* ]]; then
    PLATFORM="windows"
else
    die "Unsupported operating system: ${OS}"
fi

resolve_home() {
    if [[ -n "${HOME:-}" ]]; then
        printf '%s' "${HOME}"
        return 0
    fi
    if [[ "${PLATFORM}" == "windows" ]] && [[ -n "${USERPROFILE:-}" ]] && [[ "${USERPROFILE}" != *"%"* ]]; then
        if command -v cygpath >/dev/null 2>&1; then
            cygpath -u "${USERPROFILE}"
        else
            printf '%s' "${USERPROFILE}"
        fi
        return 0
    fi
    die "Cannot resolve HOME"
}

ensure_windows_user_env() {
    if [[ "${PLATFORM}" != "windows" ]]; then
        return 0
    fi
    local win_home
    win_home="$(cd "${SCRIPT_DIR}/../../.." 2>/dev/null && pwd || true)"
    if [[ -z "${win_home}" ]] || [[ ! -d "${win_home}/AppData/Roaming" ]]; then
        win_home="$(resolve_home)"
    fi
    if [[ -z "${HOME:-}" ]] || [[ ! -d "${HOME}/AppData/Roaming" ]]; then
        export HOME="${win_home}"
    fi
    if [[ -z "${USERPROFILE:-}" ]] || [[ "${USERPROFILE}" == *"%"* ]]; then
        if command -v cygpath >/dev/null 2>&1; then
            export USERPROFILE="$(cygpath -w "${win_home}")"
        else
            export USERPROFILE="${win_home}"
        fi
    fi
}

deploy_ideavimrc() {
    local target="$1"
    local use_copy="${2:-}"

    if [[ ! -f "${SOURCE_FILE}" ]]; then
        die "Missing config file: ${SOURCE_FILE}"
    fi

    if [[ "${IDEAVIM_DRY_RUN}" == "1" ]]; then
        log_info "[dry-run] deploy ${SOURCE_FILE} -> ${target} (copy=${use_copy})"
        return 0
    fi

    if [[ -e "${target}" ]] && [[ ! -L "${target}" ]] && [[ "${IDEAVIM_SKIP_BACKUP}" != "1" ]]; then
        local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "${target}" "${backup}"
        log_ok "Backed up existing config: ${backup}"
    fi

    if [[ "${use_copy}" == "1" ]] || [[ "${IDEAVIM_USE_COPY}" == "1" ]]; then
        cp -f "${SOURCE_FILE}" "${target}"
        log_ok "Copied config to: ${target}"
        return 0
    fi

    if [[ -e "${target}" ]] && [[ ! -L "${target}" ]]; then
        rm -f "${target}"
    fi

    if ln -sf "${SOURCE_FILE}" "${target}" 2>/dev/null; then
        log_ok "Symlinked config: ${target} -> ${SOURCE_FILE}"
        return 0
    fi

    log_warn "Symlink failed; falling back to copy"
    cp -f "${SOURCE_FILE}" "${target}"
    log_ok "Copied config to: ${target}"
}

main() {
    ensure_windows_user_env

    local home_dir
    home_dir="$(resolve_home)"
    local target_file="${home_dir}/.ideavimrc"

    echo "=========================================="
    echo "IdeaVim 配置安装"
    echo "=========================================="
    log_info "Platform: ${PLATFORM} (${OS})"
    log_info "Source: ${SOURCE_FILE}"
    log_info "Target: ${target_file}"
    echo ""

    if [[ "${PLATFORM}" == "windows" ]] && [[ "${IDEAVIM_USE_COPY}" != "1" ]]; then
        log_info "Windows: try symlink first (set IDEAVIM_USE_COPY=1 to force copy)"
        log_info "Symlink tips: git config core.symlinks true, MSYS=winsymlinks:nativestrict (see README)"
    fi

    local force_copy="0"
    if [[ "${IDEAVIM_USE_COPY}" == "1" ]]; then
        force_copy="1"
    fi

    deploy_ideavimrc "${target_file}" "${force_copy}"

    echo ""
    echo "=========================================="
    echo "安装完成"
    echo "=========================================="
    echo "配置文件: ${target_file}"
    echo "仓库源文件: ${SOURCE_FILE}"
    echo ""
    echo "下一步:"
    echo "1. 在 IntelliJ IDEA / PyCharm / WebStorm 等安装 IdeaVim 插件"
    echo "2. 重启 IDE 或执行 :source ~/.ideavimrc（快捷键 R）"
    echo "3. <leader>rc 打开 ~/.ideavimrc"
    echo ""
}

main "$@"
