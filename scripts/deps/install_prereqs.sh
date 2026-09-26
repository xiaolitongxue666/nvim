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
            # 官方预编译包。不走 Homebrew：Intel macOS 没有 uv bottle 时会从源码编译 rustc。
            _install_uv_curl || record_failed "uv"
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

# macOS 只更新 uv 自己。Homebrew 安装的 uv 会禁用 self update，此时改走官方安装脚本。
_upgrade_uv_macos() {
    _ensure_path_local_bin
    if UV_NO_MODIFY_PATH=1 uv self update; then
        return 0
    fi
    log_info "uv self update unavailable; installing official uv binary"
    UV_NO_MODIFY_PATH=1 _install_uv_curl || log_warning "uv official installer failed"
}

upgrade_uv_if_present() {
    command -v uv >/dev/null 2>&1 || return 0
    case "${PLATFORM}" in
        macos)
            _upgrade_uv_macos
            ;;
        linux)
            [[ "${PKG_MANAGER}" == "pacman" ]] && pkg_upgrade "" "" "uv" "astral-sh.uv"
            uv self update 2>/dev/null || true
            ;;
        windows)
            pkg_upgrade "" "" "" "astral-sh.uv"
            uv self update 2>/dev/null || true
            ;;
    esac
}

install_fnm_if_missing() {
    if command -v fnm >/dev/null 2>&1; then
        return 0
    fi
    log_info "Installing fnm..."
    case "${PLATFORM}" in
        macos)
            # 官方预编译包。不走 Homebrew。
            _install_fnm_curl || record_failed "fnm"
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

# macOS 只更新 fnm 自己。不走 brew upgrade。
_upgrade_fnm_macos() {
    _ensure_path_local_bin
    if fnm self-update; then
        return 0
    fi
    log_info "fnm self-update unavailable; installing official fnm binary"
    _install_fnm_curl || log_warning "fnm official installer failed"
}

upgrade_fnm_if_present() {
    command -v fnm >/dev/null 2>&1 || return 0
    case "${PLATFORM}" in
        macos)
            _upgrade_fnm_macos
            ;;
        linux)
            [[ "${PKG_MANAGER}" == "pacman" ]] && pkg_upgrade "" "" "fnm" "Schniz.fnm"
            fnm self-update 2>/dev/null || true
            ;;
        windows)
            pkg_upgrade "" "" "" "Schniz.fnm"
            fnm self-update 2>/dev/null || true
            ;;
    esac
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

    warn_mixed_windows_path
    log_success "Prerequisites ensured"
}
