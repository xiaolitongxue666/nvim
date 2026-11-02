#!/usr/bin/env bash
# git / uv / fnm 安装与升级

_ensure_path_local_bin() {
    export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"
}

# 官方安装器把二进制放在 ~/.local/share/fnm，并且只改它探测到的 shell rc
# （WSL root 常见是 zsh）。安装进程退出后，当前 shell 的 PATH 不会变。
_ensure_path_fnm() {
    local fnm_dir="${HOME}/.local/share/fnm"
    _ensure_path_local_bin
    if [[ -x "${fnm_dir}/fnm" ]]; then
        case ":${PATH}:" in
            *":${fnm_dir}:"*) ;;
            *) export PATH="${fnm_dir}:${PATH}" ;;
        esac
        hash -r
    fi
}

# 去掉首尾空白与 CR，供 cmd 展开结果使用。
_trim_cmd_value() {
    local val="${1:-}"
    val="${val//[$'\r\n']}"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"
    printf '%s\n' "${val}"
}

# 在目录树中找 uv 可执行文件（优先 uv.exe）。stdout 为路径；找不到则返回 1。
_find_uv_binary_under() {
    local root="${1:-}"
    local depth="${2:-0}"
    local child="" found=""
    [[ -n "${root}" && -d "${root}" ]] || return 1
    [[ "${depth}" -gt 4 ]] && return 1
    if [[ -f "${root}/uv.exe" ]]; then
        printf '%s\n' "${root}/uv.exe"
        return 0
    fi
    if [[ -f "${root}/uv" ]]; then
        printf '%s\n' "${root}/uv"
        return 0
    fi
    for child in "${root}"/*; do
        [[ -e "${child}" ]] || continue
        if [[ -d "${child}" ]]; then
            found="$(_find_uv_binary_under "${child}" "$((depth + 1))" || true)"
            if [[ -n "${found}" ]]; then
                printf '%s\n' "${found}"
                return 0
            fi
        fi
    done
    return 1
}

# Windows（Win10 与 Win11）：当前进程把 WinGet uv 放到 PATH 前面。
# 优先 Packages/astral-sh.uv_*，否则 WinGet/Links。不读 /mnt/c，不改 bashrc，不改 WSL。
prefer_windows_winget_uv() {
    [[ "${PLATFORM:-}" == "windows" ]] || return 0
    local localappdata="${LOCALAPPDATA:-}"
    if [[ -z "${localappdata}" || "${localappdata}" == *"%"* ]]; then
        if command -v cmd >/dev/null 2>&1; then
            localappdata="$(MSYS2_ARG_CONV_EXCL='*' cmd //c echo %LOCALAPPDATA% 2>/dev/null | tr -d '\r\n' || true)"
            localappdata="$(_trim_cmd_value "${localappdata}")"
        fi
    fi
    [[ -n "${localappdata}" && "${localappdata}" != *"%"* ]] || return 0
    case "${localappdata}" in
        /mnt/*) return 0 ;;
    esac
    local base=""
    base="$(windows_path_to_unix "${localappdata}")"
    case "${base}" in
        /mnt/*) return 0 ;;
    esac
    local packages="${base}/Microsoft/WinGet/Packages"
    local links="${base}/Microsoft/WinGet/Links"
    local pkg_dir="" uv_bin="" uv_dir=""
    for pkg_dir in "${packages}"/astral-sh.uv_*; do
        [[ -d "${pkg_dir}" ]] || continue
        uv_bin="$(_find_uv_binary_under "${pkg_dir}" || true)"
        [[ -n "${uv_bin}" ]] && break
    done
    if [[ -z "${uv_bin}" ]]; then
        if [[ -f "${links}/uv.exe" ]]; then
            uv_bin="${links}/uv.exe"
        elif [[ -f "${links}/uv" ]]; then
            uv_bin="${links}/uv"
        fi
    fi
    [[ -n "${uv_bin}" ]] || return 0
    uv_dir="$(dirname "${uv_bin}")"
    case "${uv_dir}" in
        /mnt/*) return 0 ;;
    esac
    if [[ -d "${uv_dir}" ]]; then
        uv_dir="$(cd "${uv_dir}" && pwd)"
    fi
    case "${uv_dir}" in
        /mnt/*) return 0 ;;
    esac
    export PATH="${uv_dir}:${PATH}"
    hash -r
    log_info "Using WinGet uv: ${uv_dir}"
}

# Chocolatey 或 WinGet 安装的 uv 不能 self update（包管理器持有该副本）。
_uv_path_is_package_managed() {
    local uv_path=""
    uv_path="$(command -v uv 2>/dev/null || true)"
    [[ -n "${uv_path}" ]] || return 1
    case "${uv_path}" in
        *[Cc]hocolatey*|*[Ww]in[Gg]et*) return 0 ;;
    esac
    return 1
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
    _ensure_path_fnm
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
            pkg_upgrade "" "" "" "astral-sh.uv" || true
            prefer_windows_winget_uv
            if _uv_path_is_package_managed; then
                log_info "Skipping uv self update for Chocolatey or WinGet copy"
                return 0
            fi
            uv self update 2>/dev/null || true
            ;;
    esac
}

install_fnm_if_missing() {
    _ensure_path_fnm
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
    _ensure_path_fnm
}

# macOS 只更新 fnm 自己。不走 brew upgrade。
_upgrade_fnm_macos() {
    _ensure_path_fnm
    if fnm self-update; then
        return 0
    fi
    log_info "fnm self-update unavailable; installing official fnm binary"
    _install_fnm_curl || log_warning "fnm official installer failed"
}

upgrade_fnm_if_present() {
    _ensure_path_fnm
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
            pkg_upgrade "" "" "" "Schniz.fnm" || true
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
    git_upgrade_failed=0
    command -v git >/dev/null 2>&1 || return 0
    case "${PLATFORM}" in
        macos)
            [[ "${PKG_MANAGER}" == "brew" ]] && pkg_upgrade "git" "" "" "Git.Git"
            ;;
        linux)
            pkg_upgrade "" "git" "git" ""
            ;;
        windows)
            local upgrade_status=0
            pkg_upgrade "" "" "" "Git.Git" || upgrade_status=$?
            if [[ "${upgrade_status}" -ne 0 ]]; then
                if command -v git >/dev/null 2>&1; then
                    log_warning "Git.Git upgrade failed (exit ${upgrade_status}); keeping existing git on PATH"
                    git_upgrade_failed=1
                    return 0
                fi
                return "${upgrade_status}"
            fi
            ;;
    esac
}

ensure_prerequisites() {
    log_info "Ensuring prerequisites (git, uv, fnm)..."

    install_git_if_missing
    upgrade_git_if_present
    if [[ "${git_upgrade_failed:-0}" -eq 0 ]] && command -v git >/dev/null 2>&1; then
        log_success "git: $(git --version 2>&1 | head -n 1)"
    elif ! command -v git >/dev/null 2>&1; then
        log_warning "git not available"
    fi

    install_uv_if_missing
    upgrade_uv_if_present
    prefer_windows_winget_uv
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
