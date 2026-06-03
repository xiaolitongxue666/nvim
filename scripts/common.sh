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
