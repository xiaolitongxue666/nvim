#!/usr/bin/env bash
# git / curl / tar / make(gcc) 系统工具

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

    # make / gcc：treesitter / LuaSnip 编译
    if command -v make >/dev/null 2>&1; then
        log_success "make found: $(make --version 2>&1 | head -n 1)"
    elif command -v gcc >/dev/null 2>&1; then
        log_success "gcc found (make optional): $(gcc --version 2>&1 | head -n 1)"
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
        log_info "Installing build tools (make) if package manager available..."
        pkg_install "make" "build-essential" "base-devel" "" 2>/dev/null || \
            record_failed "make (optional)"
    fi
}
