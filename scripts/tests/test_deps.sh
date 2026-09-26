#!/usr/bin/env bash
# 依赖模块单元测试（语法 + 版本解析）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMMON_LIB="${NVIM_ROOT}/scripts/common.sh"
DEPS_DIR="${NVIM_ROOT}/scripts/deps"

# shellcheck source=../common.sh
source "${COMMON_LIB}"
# shellcheck source=../deps/manifest.sh
source "${DEPS_DIR}/manifest.sh"
# shellcheck source=../deps/version.sh
source "${DEPS_DIR}/version.sh"
# shellcheck source=../deps/platform_pkg.sh
source "${DEPS_DIR}/platform_pkg.sh"
# shellcheck source=../deps/install_prereqs.sh
source "${DEPS_DIR}/install_prereqs.sh"

failures=0

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "${expected}" != "${actual}" ]]; then
        log_error "FAIL: ${desc} (expected=${expected}, actual=${actual})"
        failures=$((failures + 1))
    else
        log_success "PASS: ${desc}"
    fi
}

log_info "=== manifest arrays non-empty ==="
[[ ${#NVIM_PYTHON_PACKAGES[@]} -gt 0 ]] && log_success "NVIM_PYTHON_PACKAGES" || { log_error "empty python"; failures=$((failures + 1)); }
[[ ${#NVIM_NPM_PACKAGES[@]} -gt 0 ]] && log_success "NVIM_NPM_PACKAGES" || { log_error "empty npm"; failures=$((failures + 1)); }
[[ ${#NVIM_MASON_LSP_PACKAGES[@]} -gt 0 ]] && log_success "NVIM_MASON_LSP_PACKAGES" || { log_error "empty mason lsp"; failures=$((failures + 1)); }

log_info "=== parse_nvim_version ==="
read -r major minor <<< "$(parse_nvim_version "NVIM v0.11.5")"
assert_eq "nvim 0.11.5 major" "0" "${major}"
assert_eq "nvim 0.11.5 minor" "11" "${minor}"

read -r major minor <<< "$(parse_nvim_version "NVIM v0.10.4")"
assert_eq "nvim 0.10.4 minor" "10" "${minor}"

log_info "=== nvim_mason_all_packages dedupe ==="
mason_count=0
while IFS= read -r _; do
    mason_count=$((mason_count + 1))
done < <(nvim_mason_all_packages)
[[ ${mason_count} -ge ${#NVIM_MASON_LSP_PACKAGES[@]} ]] && log_success "mason dedupe count=${mason_count}" || {
    log_error "mason list too short: ${mason_count}"
    failures=$((failures + 1))
}

log_info "=== nvim_runtime_probe ==="
if command -v nvim >/dev/null 2>&1; then
    if nvim_runtime_probe; then
        log_success "nvim_runtime_probe OK ($(nvim_runtime_path))"
    else
        log_error "nvim_runtime_probe failed (VIMRUNTIME broken; run: sudo apt-get install -f / brew reinstall neovim)"
        failures=$((failures + 1))
    fi
else
    log_info "nvim not in PATH; runtime probe test skipped"
fi

log_info "=== brew HOMEBREW_NO_ASK (noninteractive upgrade) ==="
_saved_pkg_manager="${PKG_MANAGER:-}"
brew() {
    case "${1:-}" in
        list) return 0 ;;
        upgrade|install)
            if [[ -n "${HOMEBREW_NO_ASK:-}" ]]; then
                echo "no_ask=1"
            else
                echo "no_ask=0"
            fi
            return 0
            ;;
        *) return 0 ;;
    esac
}
PKG_MANAGER=brew
upgrade_out="$(pkg_upgrade "git" "" "" "")"
install_out="$(pkg_install "git" "" "" "")"
unset -f brew
PKG_MANAGER="${_saved_pkg_manager}"
assert_eq "pkg_upgrade brew HOMEBREW_NO_ASK" "no_ask=1" "${upgrade_out}"
assert_eq "pkg_install brew HOMEBREW_NO_ASK" "no_ask=1" "${install_out}"

log_info "=== uv upgrade stays on the official binary; OS paths stay isolated ==="
_saved_platform="${PLATFORM:-}"
_saved_pkg_manager_uv="${PKG_MANAGER:-}"

macos_install_out="$(
    PATH="/usr/bin:/bin"
    hash -r
    PLATFORM="macos"
    PKG_MANAGER="brew"
    brew() { echo "BREW:$*"; }
    curl() { printf '%s\n' 'echo OFFICIAL_INSTALLER'; }
    install_uv_if_missing
)"
if [[ "${macos_install_out}" == *BREW:* ]]; then
    log_error "FAIL: macos uv install invoked brew: ${macos_install_out}"
    failures=$((failures + 1))
else
    log_success "PASS: macos uv install skips brew"
fi
if [[ "${macos_install_out}" == *OFFICIAL_INSTALLER* ]]; then
    log_success "PASS: macos uv install uses official installer"
else
    log_error "FAIL: macos uv install missing official installer: ${macos_install_out}"
    failures=$((failures + 1))
fi

brew() { echo "BREW:$*"; }
uv() {
    if [[ "${1:-}" == "self" && "${2:-}" == "update" ]]; then
        echo "UV_SELF_UPDATE"
        return 0
    fi
    echo "UV:$*"
    return 0
}
PLATFORM="macos"
PKG_MANAGER="brew"
macos_upgrade_out="$(upgrade_uv_if_present)"
if [[ "${macos_upgrade_out}" == *BREW:* ]]; then
    log_error "FAIL: macos uv upgrade invoked brew: ${macos_upgrade_out}"
    failures=$((failures + 1))
else
    log_success "PASS: macos uv upgrade skips brew"
fi
if [[ "${macos_upgrade_out}" == *UV_SELF_UPDATE* ]]; then
    log_success "PASS: macos uv upgrade uses self update"
else
    log_error "FAIL: macos uv upgrade missing self update: ${macos_upgrade_out}"
    failures=$((failures + 1))
fi

uv() { return 1; }
_install_uv_curl() { echo "OFFICIAL_INSTALLER"; return 0; }
macos_fallback_out="$(upgrade_uv_if_present)"
if [[ "${macos_fallback_out}" == *BREW:* ]]; then
    log_error "FAIL: macos uv fallback invoked brew: ${macos_fallback_out}"
    failures=$((failures + 1))
else
    log_success "PASS: macos uv fallback skips brew"
fi
if [[ "${macos_fallback_out}" == *OFFICIAL_INSTALLER* ]]; then
    log_success "PASS: macos uv fallback uses official installer"
else
    log_error "FAIL: macos uv fallback missing official installer: ${macos_fallback_out}"
    failures=$((failures + 1))
fi
unset -f brew uv
# shellcheck source=../deps/install_prereqs.sh
source "${DEPS_DIR}/install_prereqs.sh"

pkg_upgrade() { echo "PKG_UPGRADE:$1:$2:$3:$4"; }
uv() {
    if [[ "${1:-}" == "self" && "${2:-}" == "update" ]]; then
        echo "UV_SELF_UPDATE"
        return 0
    fi
    return 0
}
PLATFORM="linux"
PKG_MANAGER="pacman"
linux_upgrade_out="$(upgrade_uv_if_present)"
assert_eq "linux uv upgrade uses pacman only" "PKG_UPGRADE:::uv:astral-sh.uv
UV_SELF_UPDATE" "${linux_upgrade_out}"

PLATFORM="windows"
PKG_MANAGER="winget"
windows_upgrade_out="$(upgrade_uv_if_present)"
assert_eq "windows uv upgrade uses winget only" "PKG_UPGRADE::::astral-sh.uv
UV_SELF_UPDATE" "${windows_upgrade_out}"
unset -f uv pkg_upgrade
# shellcheck source=../deps/platform_pkg.sh
source "${DEPS_DIR}/platform_pkg.sh"
# shellcheck source=../deps/install_prereqs.sh
source "${DEPS_DIR}/install_prereqs.sh"
PLATFORM="${_saved_platform}"
PKG_MANAGER="${_saved_pkg_manager_uv}"

log_info "=== manifest matches enabled plugins and LSP ==="
assert_eq "python packages only pynvim" "pynvim" "${NVIM_PYTHON_PACKAGES[*]}"
assert_eq "npm packages" "neovim tree-sitter-cli" "${NVIM_NPM_PACKAGES[*]}"
assert_eq "language tools" "rust c_compiler" "${NVIM_LANGUAGE_TOOLS[*]}"
assert_eq "search tools" "fd rg" "${NVIM_SEARCH_TOOLS[*]}"

log_info "=== brew refuses source builds when no bottle exists ==="
brew() {
    echo "fallback=${HOMEBREW_NO_BOTTLE_SOURCE_FALLBACK:-0}"
    return 0
}
PKG_MANAGER="brew"
fallback_out="$(pkg_install "git" "" "" "")"
unset -f brew
assert_eq "HOMEBREW_NO_BOTTLE_SOURCE_FALLBACK" "fallback=1" "${fallback_out}"

# shellcheck source=../deps/install_rust.sh
source "${DEPS_DIR}/install_rust.sh"
# shellcheck source=../deps/install_system_utils.sh
source "${DEPS_DIR}/install_system_utils.sh"

log_info "=== macos fnm upgrade skips brew ==="
brew() { echo "BREW:$*"; }
fnm() {
    if [[ "${1:-}" == "self-update" ]]; then
        echo "FNM_SELF_UPDATE"
        return 0
    fi
    return 0
}
PLATFORM="macos"
PKG_MANAGER="brew"
fnm_upgrade_out="$(upgrade_fnm_if_present)"
unset -f brew fnm
if [[ "${fnm_upgrade_out}" == *BREW:* ]]; then
    log_error "FAIL: macos fnm upgrade invoked brew: ${fnm_upgrade_out}"
    failures=$((failures + 1))
else
    log_success "PASS: macos fnm upgrade skips brew"
fi
if [[ "${fnm_upgrade_out}" == *FNM_SELF_UPDATE* ]]; then
    log_success "PASS: macos fnm upgrade uses self-update"
else
    log_error "FAIL: macos fnm upgrade missing self-update: ${fnm_upgrade_out}"
    failures=$((failures + 1))
fi

pkg_upgrade() { echo "PKG_UPGRADE:$1:$2:$3:$4"; }
fnm() { echo "FNM:$*"; return 0; }
PLATFORM="linux"
PKG_MANAGER="pacman"
linux_fnm_out="$(upgrade_fnm_if_present)"
assert_eq "linux fnm upgrade uses pacman only" "PKG_UPGRADE:::fnm:Schniz.fnm
FNM:self-update" "${linux_fnm_out}"
PLATFORM="windows"
PKG_MANAGER="winget"
windows_fnm_out="$(upgrade_fnm_if_present)"
assert_eq "windows fnm upgrade uses winget only" "PKG_UPGRADE::::Schniz.fnm
FNM:self-update" "${windows_fnm_out}"
unset -f fnm pkg_upgrade

log_info "=== rustup update does not invoke brew ==="
rust_out="$(
    fake_root="$(mktemp -d)"
    mkdir -p "${fake_root}/.cargo/bin"
    printf '#!/bin/sh\necho rustc 1.98.0\n' > "${fake_root}/.cargo/bin/rustc"
    chmod +x "${fake_root}/.cargo/bin/rustc"
    PATH="${fake_root}/.cargo/bin:/usr/bin:/bin"
    brew() { echo "BREW:$*"; }
    rustup() { echo "RUSTUP:$*"; return 0; }
    PLATFORM="macos"
    PKG_MANAGER="brew"
    ensure_rust_and_c_compiler
    rm -rf "${fake_root}"
)"
if [[ "${rust_out}" == *BREW:* ]]; then
    log_error "FAIL: rust check invoked brew: ${rust_out}"
    failures=$((failures + 1))
else
    log_success "PASS: rust check skips brew"
fi
if [[ "${rust_out}" == *RUSTUP:update\ stable* ]]; then
    log_success "PASS: rust check updates rustup stable"
else
    log_error "FAIL: rust check missing rustup update: ${rust_out}"
    failures=$((failures + 1))
fi

log_info "=== search tools are not brew-upgraded ==="
brew() { echo "BREW:$*"; }
PLATFORM="macos"
PKG_MANAGER="brew"
search_out="$(install_search_tools)"
unset -f brew
if [[ "${search_out}" == *BREW:upgrade* ]]; then
    log_error "FAIL: search tools invoked brew upgrade: ${search_out}"
    failures=$((failures + 1))
else
    log_success "PASS: search tools are not brew-upgraded"
fi
if declare -F upgrade_language_tool_packages >/dev/null 2>&1; then
    log_error "FAIL: upgrade_language_tool_packages still defined"
    failures=$((failures + 1))
else
    log_success "PASS: language-tool brew upgrades removed"
fi

PLATFORM="${_saved_platform}"
PKG_MANAGER="${_saved_pkg_manager_uv}"

log_info "=== syntax check deps ==="
for f in "${DEPS_DIR}"/*.sh; do
    bash -n "${f}" || failures=$((failures + 1))
done
bash -n "${NVIM_ROOT}/install.sh" || failures=$((failures + 1))
bash -n "${NVIM_ROOT}/scripts/windows_config.sh" || failures=$((failures + 1))

if [[ ${failures} -gt 0 ]]; then
    log_error "test_deps: ${failures} failure(s)"
    exit 1
fi
log_success "test_deps: all passed"
