#!/usr/bin/env bash
# Neovim 二进制安装/升级（>= 0.11；须与 script_tool run_once_install-neovim 同步）

NEOVIM_RELEASE_BASE="https://github.com/neovim/neovim-releases/releases/download/${NEOVIM_RELEASE_VERSION}"

_install_neovim_linux_tarball() {
    local dest_dir="${HOME}/.local/share/nvim-install"
    local bin_dir="${HOME}/.local/bin"
    mkdir -p "${dest_dir}" "${bin_dir}"
    local tarball="nvim-linux-x86_64.tar.gz"
    local url="${NEOVIM_RELEASE_BASE}/${tarball}"
    local tmp_file="${dest_dir}/${tarball}"
    log_info "Downloading Neovim ${NEOVIM_RELEASE_VERSION} tarball..."
    if command -v curl >/dev/null 2>&1; then
        curl -sL -o "${tmp_file}" "${url}" || return 1
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "${tmp_file}" "${url}" || return 1
    else
        log_warning "curl/wget required to download Neovim tarball"
        return 1
    fi
    tar xzf "${tmp_file}" -C "${dest_dir}" || return 1
    rm -f "${tmp_file}"
    ln -sf "${dest_dir}/nvim-linux-x86_64/bin/nvim" "${bin_dir}/nvim"
    export PATH="${bin_dir}:${PATH}"
    log_success "Neovim installed to ${bin_dir}/nvim"
}

_install_neovim_linux_deb() {
    local dest_dir="${HOME}/.local/share/nvim-install"
    mkdir -p "${dest_dir}"
    local deb="nvim-linux-x86_64.deb"
    local url="${NEOVIM_RELEASE_BASE}/${deb}"
    local tmp_file="${dest_dir}/${deb}"
    log_info "Downloading Neovim ${NEOVIM_RELEASE_VERSION} .deb..."
    if command -v curl >/dev/null 2>&1; then
        curl -sL -o "${tmp_file}" "${url}" || return 1
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "${tmp_file}" "${url}" || return 1
    else
        return 1
    fi
    sudo apt-get remove -y neovim neovim-runtime 2>/dev/null || true
    sudo apt-get install -y "${tmp_file}" || return 1
    rm -f "${tmp_file}"
}

_install_or_upgrade_neovim_platform() {
    case "${PLATFORM}" in
        macos)
            if [[ "${PKG_MANAGER}" == "brew" ]]; then
                if command -v nvim >/dev/null 2>&1; then
                    brew upgrade neovim 2>/dev/null || brew install neovim
                else
                    pkg_install "neovim" "" "" ""
                fi
            else
                log_warning "macOS requires Homebrew to install Neovim"
                return 1
            fi
            ;;
        linux)
            if [[ "${PKG_MANAGER}" == "pacman" ]]; then
                pkg_install "" "" "neovim" "" 2>/dev/null || true
                pkg_upgrade "" "" "neovim" ""
                if ! is_nvim_version_ge_0_11; then
                    _install_neovim_linux_tarball || return 1
                fi
            elif [[ "${PKG_MANAGER}" == "apt" ]]; then
                if command -v add-apt-repository >/dev/null 2>&1; then
                    add-apt-repository -y ppa:neovim-ppa/unstable 2>/dev/null || true
                    sudo apt-get update 2>/dev/null || true
                    pkg_install "" "neovim" "" "" 2>/dev/null || true
                fi
                pkg_upgrade "" "neovim" "" "Neovim.Neovim"
                if ! is_nvim_version_ge_0_11; then
                    _install_neovim_linux_deb || _install_neovim_linux_tarball || return 1
                fi
            elif [[ "${PKG_MANAGER}" == "dnf" || "${PKG_MANAGER}" == "yum" ]]; then
                pkg_install "" "neovim" "neovim" "" 2>/dev/null || true
                pkg_upgrade "" "neovim" "neovim" ""
                if ! is_nvim_version_ge_0_11; then
                    _install_neovim_linux_tarball || return 1
                fi
            else
                _install_neovim_linux_tarball || return 1
            fi
            ;;
        windows)
            if [[ "${PKG_MANAGER}" == "winget" ]]; then
                if command -v nvim >/dev/null 2>&1; then
                    pkg_upgrade "" "" "" "Neovim.Neovim"
                else
                    pkg_install "" "" "" "Neovim.Neovim" 2>/dev/null || true
                fi
            elif [[ "${PKG_MANAGER}" == "pacman" ]]; then
                pkg_install "" "" "neovim" "" 2>/dev/null || true
                pkg_upgrade "" "" "neovim" ""
            fi
            if ! is_nvim_version_ge_0_11; then
                log_warning "Neovim may be below 0.11; install manually from https://github.com/neovim/neovim-releases/releases"
                return 1
            fi
            ;;
        *)
            log_warning "Unsupported platform for Neovim install"
            return 1
            ;;
    esac
    return 0
}

install_neovim_binary() {
    log_info "Checking Neovim binary (>= 0.11.0)..."

    if command -v nvim >/dev/null 2>&1 && is_nvim_version_ge_0_11; then
        log_success "Neovim OK: $(nvim --version 2>&1 | head -n 1)"
        log_info "Attempting platform upgrade for latest stable..."
        _install_or_upgrade_neovim_platform || true
        if is_nvim_version_ge_0_11; then
            log_success "Neovim after upgrade: $(nvim --version 2>&1 | head -n 1)"
        fi
        return 0
    fi

    if command -v nvim >/dev/null 2>&1; then
        log_info "Neovim below 0.11.0: $(nvim --version 2>&1 | head -n 1)"
    else
        log_info "Neovim not found; installing ${NEOVIM_RELEASE_VERSION} or latest via package manager..."
    fi

    if _install_or_upgrade_neovim_platform; then
        if is_nvim_version_ge_0_11; then
            log_success "Neovim installed: $(nvim --version 2>&1 | head -n 1)"
            return 0
        fi
    fi

    record_failed "neovim"
    log_warning "Neovim install/upgrade incomplete; need >= 0.11.0"
    return 0
}
