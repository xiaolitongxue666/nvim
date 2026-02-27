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
