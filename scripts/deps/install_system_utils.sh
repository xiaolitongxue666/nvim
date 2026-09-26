#!/usr/bin/env bash
# git / curl / tar。make 与 C 编译器只检测，不安装。fd / rg 见 install_search_tools。

install_system_utils() {
    log_info "Checking system utilities (git, curl, tar, make)..."

    local pkg brew_name apt_name pacman_name winget_id
    for pkg in "${NVIM_SYSTEM_PACKAGES[@]}"; do
        case "${pkg}" in
            git)
                brew_name="git"; apt_name="git"; pacman_name="git"; winget_id="Git.Git"
                ;;
            curl)
                brew_name="curl"; apt_name="curl"; pacman_name="curl"; winget_id=""
                ;;
            tar)
                brew_name=""; apt_name="tar"; pacman_name="tar"; winget_id=""
                ;;
            *)
                continue
                ;;
        esac
        if ! command -v "${pkg}" >/dev/null 2>&1; then
            log_info "Installing ${pkg}..."
            pkg_install "${brew_name}" "${apt_name}" "${pacman_name}" "${winget_id}" \
                || record_failed "${pkg}"
        else
            log_success "${pkg} found: $(command -v "${pkg}")"
            pkg_upgrade "${brew_name}" "${apt_name}" "${pacman_name}" "${winget_id}" || true
        fi
    done

    if command -v make >/dev/null 2>&1; then
        log_success "make found: $(make --version 2>&1 | head -n 1)"
    elif command -v gcc >/dev/null 2>&1 || command -v clang >/dev/null 2>&1; then
        log_success "C compiler found; make is optional for LuaSnip jsregexp"
    elif [[ "${PLATFORM}" == "windows" ]]; then
        local mingw_ok=0
        if [[ -n "${MINGW_PREFIX:-}" ]] && command -v "${MINGW_PREFIX}/bin/gcc.exe" >/dev/null 2>&1; then
            mingw_ok=1
        fi
        if [[ ${mingw_ok} -eq 0 ]] && [[ -d "/c/ProgramData/mingw64/mingw64/bin" ]]; then
            export PATH="/c/ProgramData/mingw64/mingw64/bin:${PATH}"
            command -v gcc >/dev/null 2>&1 && mingw_ok=1
        fi
        if [[ ${mingw_ok} -eq 1 ]]; then
            log_success "MinGW gcc found on Windows"
        else
            log_warning "Windows: no make/gcc in PATH; TreeSitter compile / LuaSnip jsregexp may fail (see TROUBLE_SHOOT.md)"
            record_failed "make/gcc (optional)"
        fi
    else
        log_info "make not installed; LuaSnip jsregexp build will be skipped"
    fi
}

# neo-tree 需要 fd，spectre 需要 rg。缺失才安装，不升级。
_link_fdfind_as_fd() {
    command -v fd >/dev/null 2>&1 && return 0
    command -v fdfind >/dev/null 2>&1 || return 1
    mkdir -p "${HOME}/.local/bin"
    ln -sfn "$(command -v fdfind)" "${HOME}/.local/bin/fd"
    export PATH="${HOME}/.local/bin:${PATH}"
    log_success "fd linked from fdfind"
}

_install_search_command() {
    local cmd_name="$1"
    if command -v "${cmd_name}" >/dev/null 2>&1; then
        log_success "${cmd_name} found: $(command -v "${cmd_name}")"
        return 0
    fi
    if [[ "${cmd_name}" == "fd" ]] && _link_fdfind_as_fd; then
        return 0
    fi
    log_info "Installing ${cmd_name}..."
    case "${PLATFORM}" in
        macos)
            if [[ "${cmd_name}" == "fd" ]]; then
                pkg_install "fd" "" "" "" || record_failed "fd"
            else
                pkg_install "ripgrep" "" "" "" || record_failed "rg"
            fi
            ;;
        linux)
            if [[ "${cmd_name}" == "fd" ]]; then
                pkg_install "" "fd-find" "fd" "" || record_failed "fd"
                _link_fdfind_as_fd || true
            else
                pkg_install "" "ripgrep" "ripgrep" "" || record_failed "rg"
            fi
            ;;
        windows)
            if [[ "${cmd_name}" == "fd" ]]; then
                pkg_install "" "" "fd" "sharkdp.fd" || record_failed "fd"
            else
                pkg_install "" "" "ripgrep" "BurntSushi.ripgrep.MSVC" || record_failed "rg"
            fi
            ;;
    esac
}

install_search_tools() {
    log_info "Checking search tools (fd, ripgrep)..."
    local cmd_name
    for cmd_name in "${NVIM_SEARCH_TOOLS[@]}"; do
        _install_search_command "${cmd_name}"
    done
}
