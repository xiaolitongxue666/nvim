#!/usr/bin/env bash
# 运行时上下文：PLATFORM / IS_WSL / PKG_MANAGER

# 依赖 common.sh 的 is_wsl_platform / is_windows_platform

detect_runtime_context() {
    local os
    os="$(uname -s 2>/dev/null || echo "")"

    IS_WSL=0
    if is_wsl_platform; then
        IS_WSL=1
    fi

    if [[ "${os}" == "Darwin" ]]; then
        PLATFORM="macos"
    elif [[ "${os}" == "Linux" ]]; then
        PLATFORM="linux"
    elif [[ "${os}" == MINGW* ]] || [[ "${os}" == MSYS* ]] || [[ "${os}" == CYGWIN* ]]; then
        PLATFORM="windows"
    else
        error_exit "Unsupported operating system: ${os}"
    fi

    PKG_MANAGER=""
    case "${PLATFORM}" in
        macos)
            command -v brew >/dev/null 2>&1 && PKG_MANAGER="brew"
            ;;
        linux)
            if command -v pacman >/dev/null 2>&1; then
                PKG_MANAGER="pacman"
            elif command -v apt-get >/dev/null 2>&1; then
                PKG_MANAGER="apt"
            elif command -v dnf >/dev/null 2>&1; then
                PKG_MANAGER="dnf"
            elif command -v yum >/dev/null 2>&1; then
                PKG_MANAGER="yum"
            fi
            ;;
        windows)
            if command -v winget >/dev/null 2>&1; then
                PKG_MANAGER="winget"
            elif command -v pacman.exe >/dev/null 2>&1; then
                PKG_MANAGER="pacman"
            fi
            ;;
    esac

    if [[ "${IS_WSL}" -eq 1 ]]; then
        log_info "[WSL] Runtime: PLATFORM=${PLATFORM} PKG_MANAGER=${PKG_MANAGER:-none}"
    else
        log_info "Runtime: PLATFORM=${PLATFORM} PKG_MANAGER=${PKG_MANAGER:-none}"
    fi
}

# WSL 下若 node 来自 Windows PATH，打 WARNING
warn_mixed_windows_path() {
    [[ "${IS_WSL:-0}" -eq 1 ]] || return 0
    local node_path=""
    node_path="$(command -v node 2>/dev/null || true)"
    if [[ -n "${node_path}" && "${node_path}" == /mnt/c/* ]]; then
        log_warning "WSL: node is from Windows PATH (${node_path}); use Linux-side fnm/npm instead"
    fi
    local ts_path=""
    ts_path="$(command -v tree-sitter 2>/dev/null || true)"
    if [[ -n "${ts_path}" && "${ts_path}" == /mnt/c/* ]]; then
        log_warning "WSL: tree-sitter is from Windows PATH (${ts_path}); install via Linux fnm/npm"
    fi
}
