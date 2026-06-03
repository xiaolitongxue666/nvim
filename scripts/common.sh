#!/usr/bin/env bash
# 本仓库安装脚本使用的通用日志与错误处理函数（独立于父仓库）

log_info() {
    printf '\033[0;36m[INFO]\033[0m %s\n' "$*"
}

log_success() {
    printf '\033[0;32m[SUCCESS]\033[0m %s\n' "$*"
}

log_warning() {
    printf '\033[0;33m[WARN]\033[0m %s\n' "$*" >&2
}

log_error() {
    printf '\033[0;31m[ERROR]\033[0m %s\n' "$*" >&2
}

error_exit() {
    log_error "$1"
    exit 1
}

start_script() {
    local title="${1:-Script}"
    printf '\n\033[0;34m========== %s ==========\033[0m\n' "${title}"
}

end_script() {
    printf '\033[0;34m========== Done ==========\033[0m\n\n'
}

# 确保目录存在，不存在则创建（mkdir -p）
ensure_directory() {
    local dir="$1"
    if [[ -z "${dir}" ]]; then
        return 1
    fi
    if [[ ! -d "${dir}" ]]; then
        mkdir -p "${dir}"
    fi
}

# 带超时运行命令（macOS 无 timeout 时直接执行）
run_with_timeout() {
    local seconds="$1"
    shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "${seconds}" "$@"
    else
        "$@"
    fi
}

# Windows 路径 → Git Bash Unix 绝对路径
# 例：C:\Users\foo → /c/Users/foo
windows_path_to_unix() {
    local p="$1"
    p="${p//\\//}"
    if [[ "$p" =~ ^/([a-zA-Z])/(.*)$ ]]; then
        printf '/%s/%s\n' "${BASH_REMATCH[1],,}" "${BASH_REMATCH[2]}"
    elif [[ "$p" =~ ^([a-zA-Z]):/(.*)$ ]]; then
        printf '/%s/%s\n' "${BASH_REMATCH[1],,}" "${BASH_REMATCH[2]}"
    elif [[ "$p" =~ ^([a-zA-Z]):(.*)$ ]]; then
        printf '/%s/%s\n' "${BASH_REMATCH[1],,}" "${BASH_REMATCH[2]}"
    else
        printf '%s\n' "$p"
    fi
}

# Git Bash Unix 绝对路径 → Windows 路径（供 cmd.exe / mklink）
# 例：/c/Users/foo → C:\Users\foo
unix_path_to_windows() {
    local p="$1"
    p="${p//\\//}"
    if [[ "$p" =~ ^/([a-z])/(.*)$ ]]; then
        local drive
        drive="$(printf '%s' "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')"
        printf '%s:\\%s\n' "${drive}" "${BASH_REMATCH[2]//\//\\}"
    else
        printf '%s\n' "$p"
    fi
}

# 校验 Git Bash 绝对路径（必须以 /x/ 开头，防止相对路径误建目录）
is_gitbash_absolute_path() {
    local p="$1"
    [[ "$p" =~ ^/[a-zA-Z]/ ]]
}

# 检测是否为 Windows Git Bash 环境
is_windows_platform() {
    local os
    os="$(uname -s 2>/dev/null || echo "")"
    [[ "${os}" == MINGW* ]] || [[ "${os}" == MSYS* ]] || [[ "${os}" == CYGWIN* ]]
}

# 无头/安装脚本共用：展开 USERPROFILE / LOCALAPPDATA / XDG_CONFIG_HOME
ensure_windows_user_env() {
    is_windows_platform || return 0

    local userprofile localappdata xdg_unix

    userprofile="$(cmd //c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r\n' || true)"
    userprofile="${userprofile//[$'\r\n']}"
    if [[ -n "${userprofile}" ]] && [[ "${userprofile}" != *"%"* ]]; then
        export USERPROFILE="${userprofile//\\//}"
    elif [[ -n "${HOME:-}" ]] && command -v cygpath >/dev/null 2>&1; then
        export USERPROFILE="$(cygpath -w "${HOME}" 2>/dev/null || true)"
    fi

    if [[ -z "${HOME:-}" ]] || [[ "${HOME}" == /home/* ]]; then
        if [[ -n "${USERPROFILE:-}" ]] && [[ "${USERPROFILE}" =~ ^([A-Za-z]):\\?(.*)$ ]]; then
            local rest="${BASH_REMATCH[2]//\\//}"
            rest="${rest#/}"
            HOME="/$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')/${rest}"
            export HOME
        fi
    fi

    localappdata="$(cmd //c "echo %LOCALAPPDATA%" 2>/dev/null | tr -d '\r\n' || true)"
    localappdata="${localappdata//[$'\r\n']}"
    if [[ -n "${localappdata}" ]] && [[ "${localappdata}" != *"%"* ]]; then
        export LOCALAPPDATA="${localappdata}"
    fi

    xdg_unix="${XDG_CONFIG_HOME:-${HOME}/.config}"
    if command -v cygpath >/dev/null 2>&1; then
        export XDG_CONFIG_HOME="$(cygpath -w "${xdg_unix}" 2>/dev/null || echo "${xdg_unix}")"
    else
        export XDG_CONFIG_HOME="${xdg_unix}"
    fi
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME//\\//}"
}

# Windows：清理 Win10 packer 残留（lazy checkhealth WARNING）
cleanup_legacy_packer() {
    is_windows_platform || return 0

    local nvim_data_unix=""
    if [[ -n "${LOCALAPPDATA:-}" ]] && [[ "${LOCALAPPDATA}" != *"%"* ]]; then
        nvim_data_unix="$(windows_path_to_unix "${LOCALAPPDATA}/nvim-data")"
    elif [[ -n "${HOME:-}" ]] && [[ -d "${HOME}/AppData/Local/nvim-data" ]]; then
        nvim_data_unix="${HOME}/AppData/Local/nvim-data"
    fi
    [[ -z "${nvim_data_unix}" ]] && return 0

    local packer_dir="${nvim_data_unix}/site/pack/packer"
    local backup_root="${nvim_data_unix}/backups"
    ensure_directory "${backup_root}"

    if [[ -d "${packer_dir}" ]]; then
        local backup_dir="${backup_root}/packer.$(date +%Y%m%d_%H%M%S)"
        log_info "Backing up legacy packer plugins (Win10 migration residue): ${packer_dir}"
        if mv "${packer_dir}" "${backup_dir}" 2>/dev/null; then
            log_success "Legacy packer removed (backup: ${backup_dir})"
        else
            log_warning "Could not remove legacy packer directory: ${packer_dir}"
        fi
    fi

    # 旧版 cleanup 曾放在 site/pack/ 下，lazy 仍会误报
    local old_backup
    for old_backup in "${nvim_data_unix}/site/pack/packer.backup."*; do
        [[ -e "${old_backup}" ]] || continue
        mv "${old_backup}" "${backup_root}/$(basename "${old_backup}").migrated" 2>/dev/null || rm -rf "${old_backup}"
        log_info "Moved stray packer backup out of site/pack: ${old_backup}"
    done
}

# 无头验收可选代理（USE_PROXY=0 关闭；默认 127.0.0.1:7890）
setup_headless_proxy() {
    is_windows_platform || return 0
    [[ "${USE_PROXY:-1}" != "1" ]] && return 0
    local proxy_host="${PROXY_HOST:-127.0.0.1}"
    local proxy_port="${PROXY_PORT:-7890}"
    export http_proxy="http://${proxy_host}:${proxy_port}"
    export https_proxy="http://${proxy_host}:${proxy_port}"
    export HTTP_PROXY="http://${proxy_host}:${proxy_port}"
    export HTTPS_PROXY="http://${proxy_host}:${proxy_port}"
    export NVIM_PROXY_URL="http://${proxy_host}:${proxy_port}"
}
