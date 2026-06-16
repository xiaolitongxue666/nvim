#!/usr/bin/env bash
# git / uv / fnm 安装与升级

_ensure_path_local_bin() {
    export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"
}

_install_uv_curl() {
    if ! command -v curl >/dev/null 2>&1; then
        log_warning "curl not found; cannot install uv via official script"
        return 1
    fi
    curl -LsSf https://astral.sh/uv/install.sh | sh || return 1
    _ensure_path_local_bin
}

_install_fnm_curl() {
    if ! command -v curl >/dev/null 2>&1; then
        log_warning "curl not found; cannot install fnm via official script"
        return 1
    fi
    curl -fsSL https://fnm.vercel.app/install | bash || return 1
    _ensure_path_local_bin
}

install_uv_if_missing() {
    if command -v uv >/dev/null 2>&1; then
        return 0
    fi
    log_info "Installing uv..."
    case "${PLATFORM}" in
        macos)
            if [[ "${PKG_MANAGER}" == "brew" ]]; then
                pkg_install "uv" "" "" "" || _install_uv_curl || record_failed "uv"
            else
                _install_uv_curl || record_failed "uv"
            fi
            ;;
        linux)
            if [[ "${PKG_MANAGER}" == "pacman" ]]; then
                pkg_install "" "" "uv" "" || _install_uv_curl || record_failed "uv"
            else
                _install_uv_curl || record_failed "uv"
            fi
            ;;
        windows)
            if [[ "${PKG_MANAGER}" == "winget" ]]; then
                pkg_install "" "" "" "astral-sh.uv" || _install_uv_curl || record_failed "uv"
            else
                _install_uv_curl || record_failed "uv"
            fi
            ;;
    esac
    _ensure_path_local_bin
}

upgrade_uv_if_present() {
    command -v uv >/dev/null 2>&1 || return 0
    case "${PLATFORM}" in
        macos)
            [[ "${PKG_MANAGER}" == "brew" ]] && pkg_upgrade "uv" "" "" "astral-sh.uv"
            ;;
        linux)
            [[ "${PKG_MANAGER}" == "pacman" ]] && pkg_upgrade "" "" "uv" "astral-sh.uv"
            ;;
        windows)
            pkg_upgrade "" "" "" "astral-sh.uv"
            ;;
    esac
    uv self update 2>/dev/null || true
}

install_fnm_if_missing() {
    if command -v fnm >/dev/null 2>&1; then
        return 0
    fi
    log_info "Installing fnm..."
    case "${PLATFORM}" in
        macos)
            if [[ "${PKG_MANAGER}" == "brew" ]]; then
                pkg_install "fnm" "" "" "" || _install_fnm_curl || record_failed "fnm"
            else
                _install_fnm_curl || record_failed "fnm"
            fi
            ;;
        linux)
            if [[ "${PKG_MANAGER}" == "pacman" ]]; then
                pkg_install "" "" "fnm" "" || _install_fnm_curl || record_failed "fnm"
            else
                _install_fnm_curl || record_failed "fnm"
            fi
            ;;
        windows)
            if [[ "${PKG_MANAGER}" == "winget" ]]; then
                pkg_install "" "" "" "Schniz.fnm" || _install_fnm_curl || record_failed "fnm"
            else
                _install_fnm_curl || record_failed "fnm"
            fi
            ;;
    esac
    _ensure_path_local_bin
}

upgrade_fnm_if_present() {
    command -v fnm >/dev/null 2>&1 || return 0
    case "${PLATFORM}" in
        macos)
            [[ "${PKG_MANAGER}" == "brew" ]] && pkg_upgrade "fnm" "" "" "Schniz.fnm"
            ;;
        linux)
            [[ "${PKG_MANAGER}" == "pacman" ]] && pkg_upgrade "" "" "fnm" "Schniz.fnm"
            ;;
        windows)
            pkg_upgrade "" "" "" "Schniz.fnm"
            ;;
    esac
    fnm self-update 2>/dev/null || true
}

install_git_if_missing() {
    if command -v git >/dev/null 2>&1; then
        return 0
    fi
    log_info "Installing git..."
    case "${PLATFORM}" in
        macos)
            [[ "${PKG_MANAGER}" == "brew" ]] && pkg_install "git" "" "" "" || record_failed "git"
            ;;
        linux)
            pkg_install "" "git" "git" "" || record_failed "git"
            ;;
        windows)
            pkg_install "" "" "" "Git.Git" || record_failed "git"
            ;;
    esac
}

upgrade_git_if_present() {
    command -v git >/dev/null 2>&1 || return 0
    case "${PLATFORM}" in
        macos)
            [[ "${PKG_MANAGER}" == "brew" ]] && pkg_upgrade "git" "" "" "Git.Git"
            ;;
        linux)
            pkg_upgrade "" "git" "git" ""
            ;;
        windows)
            pkg_upgrade "" "" "" "Git.Git"
            ;;
    esac
}

ensure_prerequisites() {
    log_info "Ensuring prerequisites (git, uv, fnm)..."

    install_git_if_missing
    upgrade_git_if_present
    if command -v git >/dev/null 2>&1; then
        log_success "git: $(git --version 2>&1 | head -n 1)"
    else
        log_warning "git not available"
    fi

    install_uv_if_missing
    upgrade_uv_if_present
    if command -v uv >/dev/null 2>&1; then
        log_success "uv: $(uv --version 2>&1 | head -n 1)"
    else
        error_exit "uv is not available after install attempt. Re-login or add ~/.local/bin to PATH"
    fi

    install_fnm_if_missing
    upgrade_fnm_if_present
    if command -v fnm >/dev/null 2>&1; then
        log_success "fnm: $(fnm --version 2>&1 | head -n 1)"
    else
        error_exit "fnm is not available after install attempt. Re-login or add fnm to PATH"
    fi

    # 可选 Lua
    local lua_installed=0
    if command -v lua >/dev/null 2>&1; then
        lua_installed=1
        log_success "Lua found: $(lua -v 2>&1 | head -n 1)"
    elif [[ "${PLATFORM}" == "linux" ]] && [[ "${PKG_MANAGER}" == "pacman" ]]; then
        if pacman -Qi lua >/dev/null 2>&1; then
            lua_installed=1
            log_success "Lua found via pacman"
        fi
    fi
    if [[ ${lua_installed} -eq 0 ]]; then
        log_info "Lua is not installed (optional for Neovim)"
        record_failed "Lua"
        install_lua 2>/dev/null || true
    fi

    warn_mixed_windows_path
    log_success "Prerequisites ensured"
}
