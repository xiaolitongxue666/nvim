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
windows_upgrade_out="$(
    unset -f uv
    tmp="$(mktemp -d)"
    choco="${tmp}/chocolatey/bin"
    pkgdir="${tmp}/Microsoft/WinGet/Packages/astral-sh.uv_fixture"
    mkdir -p "${choco}" "${pkgdir}" "${tmp}/empty-local"
    cat > "${choco}/uv" <<'EOF'
#!/bin/sh
printf 'choco-uv %s\n' "$*"
EOF
    cat > "${pkgdir}/uv" <<'EOF'
#!/bin/sh
if [ "$1" = "self" ]; then
    printf 'UV_SELF_UPDATE\n'
fi
printf 'winget-uv %s\n' "$*"
EOF
    chmod +x "${choco}/uv" "${pkgdir}/uv"
    HOME="${tmp}/home"
    LOCALAPPDATA="${tmp}"
    PATH="${choco}:/usr/bin:/bin"
    hash -r
    upgrade_uv_if_present
    rm -rf "${tmp}"
)"
if [[ "${windows_upgrade_out}" == *"PKG_UPGRADE::::astral-sh.uv"* ]]; then
    log_success "PASS: windows uv upgrade still calls winget"
else
    log_error "FAIL: windows uv upgrade missing winget pkg_upgrade: ${windows_upgrade_out}"
    failures=$((failures + 1))
fi
if [[ "${windows_upgrade_out}" == *"UV_SELF_UPDATE"* || "${windows_upgrade_out}" == *"choco-uv"* ]]; then
    log_error "FAIL: windows winget/chocolatey uv ran self update: ${windows_upgrade_out}"
    failures=$((failures + 1))
else
    log_success "PASS: windows winget uv upgrade skips self update"
fi
windows_official_out="$(
    unset -f uv
    tmp="$(mktemp -d)"
    mkdir -p "${tmp}/home/.local/bin" "${tmp}/empty-local"
    cat > "${tmp}/home/.local/bin/uv" <<'EOF'
#!/bin/sh
if [ "$1" = "self" ] && [ "$2" = "update" ]; then
    printf 'UV_SELF_UPDATE\n'
fi
exit 0
EOF
    chmod +x "${tmp}/home/.local/bin/uv"
    HOME="${tmp}/home"
    LOCALAPPDATA="${tmp}/empty-local"
    PATH="${HOME}/.local/bin:/usr/bin:/bin"
    hash -r
    upgrade_uv_if_present
    rm -rf "${tmp}"
)"
if [[ "${windows_official_out}" == *"PKG_UPGRADE::::astral-sh.uv"* && "${windows_official_out}" == *"UV_SELF_UPDATE"* ]]; then
    log_success "PASS: windows official uv still self-updates"
else
    log_error "FAIL: windows official uv self update: ${windows_official_out}"
    failures=$((failures + 1))
fi
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

log_info "=== fnm binary under ~/.local/share/fnm is visible in the current shell ==="
fnm_offpath_out="$(
    fake_home="$(mktemp -d)"
    mkdir -p "${fake_home}/.local/share/fnm"
    printf '#!/bin/sh\nprintf "fnm 1.39.0\\n"\n' > "${fake_home}/.local/share/fnm/fnm"
    chmod +x "${fake_home}/.local/share/fnm/fnm"
    HOME="${fake_home}"
    PATH="/usr/bin:/bin"
    hash -r
    curl() { echo "SHOULD_NOT_CURL"; return 1; }
    PLATFORM="linux"
    PKG_MANAGER="apt"
    install_fnm_if_missing
    command -v fnm
    fnm --version
    rm -rf "${fake_home}"
)"
if [[ "${fnm_offpath_out}" == *SHOULD_NOT_CURL* ]]; then
    log_error "FAIL: existing fnm binary triggered a reinstall: ${fnm_offpath_out}"
    failures=$((failures + 1))
else
    log_success "PASS: existing fnm binary skips reinstall"
fi
if [[ "${fnm_offpath_out}" == *fnm\ 1.39.0* ]]; then
    log_success "PASS: off-PATH fnm becomes visible"
else
    log_error "FAIL: off-PATH fnm still hidden: ${fnm_offpath_out}"
    failures=$((failures + 1))
fi

fnm_after_install_out="$(
    fake_home="$(mktemp -d)"
    HOME="${fake_home}"
    PATH="/usr/bin:/bin"
    hash -r
    curl() {
        mkdir -p "${HOME}/.local/share/fnm"
        printf '#!/bin/sh\nprintf "fnm 1.39.0\\n"\n' > "${HOME}/.local/share/fnm/fnm"
        chmod +x "${HOME}/.local/share/fnm/fnm"
        return 0
    }
    PLATFORM="linux"
    PKG_MANAGER="apt"
    install_fnm_if_missing
    command -v fnm
    rm -rf "${fake_home}"
)"
case "${fnm_after_install_out}" in
    *"/.local/share/fnm/fnm"*)
        log_success "PASS: installer result is on PATH"
        ;;
    *)
        log_error "FAIL: installer result still off PATH: ${fnm_after_install_out}"
        failures=$((failures + 1))
        ;;
esac

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

log_info "=== winget exit code, git upgrade, and WinGet uv path ==="
# shellcheck source=../deps/platform_pkg.sh
source "${DEPS_DIR}/platform_pkg.sh"
# shellcheck source=../deps/install_prereqs.sh
source "${DEPS_DIR}/install_prereqs.sh"
# shellcheck source=../deps/install_system_utils.sh
source "${DEPS_DIR}/install_system_utils.sh"
# shellcheck source=../deps/install_python.sh
source "${DEPS_DIR}/install_python.sh"
# shellcheck source=../deps/install_node.sh
source "${DEPS_DIR}/install_node.sh"
if ! declare -F record_failed >/dev/null 2>&1; then
    record_failed() { printf 'RECORD_FAILED %s\n' "$*"; }
fi

_saved_platform_fix="${PLATFORM:-}"
_saved_pkg_fix="${PKG_MANAGER:-}"
_saved_path_fix="${PATH}"
_saved_appdata_fix="${APPDATA:-}"
_saved_localappdata_fix="${LOCALAPPDATA:-}"
_saved_fnm_dir_fix="${FNM_DIR:-}"

winget_fake="$(mktemp -d)"
cat > "${winget_fake}/winget" <<'EOF'
#!/bin/sh
printf 'ran\n' > "${WINGET_MARKER}"
exit 1
EOF
chmod +x "${winget_fake}/winget"
WINGET_MARKER="${winget_fake}/ran"
export WINGET_MARKER
hash -r
winget_status=0
PATH="${winget_fake}:/usr/bin:/bin" _pkg_winget upgrade --id Git.Git -e || winget_status=$?
if [[ "${winget_status}" -ne 0 && -f "${WINGET_MARKER}" ]]; then
    log_success "PASS: fake winget exit 1 makes _pkg_winget return non-zero"
else
    log_error "FAIL: _pkg_winget swallowed winget failure (status=${winget_status})"
    failures=$((failures + 1))
fi
rm -rf "${winget_fake}"
unset WINGET_MARKER

winget_slow="$(mktemp -d)"
cat > "${winget_slow}/winget" <<'EOF'
#!/bin/sh
sleep 30
exit 0
EOF
chmod +x "${winget_slow}/winget"
hash -r
slow_status=0
WINGET_TIMEOUT_SECS=1 PATH="${winget_slow}:/usr/bin:/bin" _pkg_winget upgrade --id Git.Git -e || slow_status=$?
if [[ "${slow_status}" -ne 0 ]]; then
    log_success "PASS: winget timeout is non-zero"
else
    log_error "FAIL: winget timeout returned 0"
    failures=$((failures + 1))
fi
rm -rf "${winget_slow}"

git_fake="$(mktemp -d)"
mkdir -p "${git_fake}/bin"
cat > "${git_fake}/bin/git" <<'EOF'
#!/bin/sh
printf 'git version 2.0.0\n'
EOF
cat > "${git_fake}/bin/winget" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "${WINGET_CALL_LOG}"
exit 1
EOF
chmod +x "${git_fake}/bin/git" "${git_fake}/bin/winget"
WINGET_CALL_LOG="${git_fake}/calls"
export WINGET_CALL_LOG
: > "${WINGET_CALL_LOG}"
hash -r
PLATFORM="windows"
PKG_MANAGER="winget"
git_upgrade_failed=0
upgrade_out="$(
    PATH="${git_fake}/bin:/usr/bin:/bin"
    hash -r
    upgrade_git_if_present
)"
utils_out="$(
    PATH="${git_fake}/bin:/usr/bin:/bin"
    hash -r
    install_system_utils
)"
winget_calls="$(grep -c . "${WINGET_CALL_LOG}" || true)"
if printf '%s\n' "${upgrade_out}" | grep -F '[SUCCESS]' >/dev/null; then
    log_error "FAIL: failed git upgrade logged SUCCESS: ${upgrade_out}"
    failures=$((failures + 1))
else
    log_success "PASS: failed git upgrade does not log SUCCESS"
fi
if printf '%s\n' "${utils_out}" | grep -F '[SUCCESS] git' >/dev/null; then
    log_error "FAIL: install_system_utils logged git SUCCESS after failed upgrade: ${utils_out}"
    failures=$((failures + 1))
else
    log_success "PASS: install_system_utils does not log git SUCCESS when upgrade failed"
fi
if [[ "${winget_calls}" -eq 1 ]] && grep -F 'Git.Git' "${WINGET_CALL_LOG}" >/dev/null; then
    log_success "PASS: Git.Git upgrade runs once when git already exists"
else
    log_error "FAIL: Git.Git upgrade count=${winget_calls} log=$(cat "${WINGET_CALL_LOG}")"
    failures=$((failures + 1))
fi
rm -rf "${git_fake}"
unset WINGET_CALL_LOG

uv_fake="$(mktemp -d)"
mkdir -p "${uv_fake}/chocolatey/bin" \
    "${uv_fake}/Microsoft/WinGet/Packages/astral-sh.uv_fixture" \
    "${uv_fake}/Microsoft/WinGet/Links" \
    "${uv_fake}/home/.config/nvim/venv/nvim-python/Scripts"
printf 'kept\n' > "${uv_fake}/home/.config/nvim/venv/nvim-python/MARKER"
printf 'true\n' > "${uv_fake}/home/.config/nvim/venv/nvim-python/Scripts/activate"
UV_CALL_LOG="${uv_fake}/uv-calls"
export UV_CALL_LOG
: > "${UV_CALL_LOG}"
cat > "${uv_fake}/chocolatey/bin/uv" <<'EOF'
#!/bin/sh
printf 'CHOCO %s\n' "$*" >> "${UV_CALL_LOG}"
exit 0
EOF
cat > "${uv_fake}/Microsoft/WinGet/Packages/astral-sh.uv_fixture/uv" <<'EOF'
#!/bin/sh
printf 'PKG %s\n' "$*" >> "${UV_CALL_LOG}"
exit 0
EOF
cat > "${uv_fake}/Microsoft/WinGet/Links/uv" <<'EOF'
#!/bin/sh
printf 'LINK %s\n' "$*" >> "${UV_CALL_LOG}"
exit 0
EOF
chmod +x "${uv_fake}/chocolatey/bin/uv" \
    "${uv_fake}/Microsoft/WinGet/Packages/astral-sh.uv_fixture/uv" \
    "${uv_fake}/Microsoft/WinGet/Links/uv"
uv_resolve_out="$(
    unset -f uv
    HOME="${uv_fake}/home"
    LOCALAPPDATA="${uv_fake}"
    PLATFORM="windows"
    PKG_MANAGER="winget"
    USE_SYSTEM_NVIM_VENV=0
    PATH="${uv_fake}/chocolatey/bin:/usr/bin:/bin"
    hash -r
    prefer_windows_winget_uv
    command -v uv
    setup_python_environment
)"
if [[ "${uv_resolve_out}" == *"astral-sh.uv_fixture"* && "${uv_resolve_out}" != *"chocolatey"* ]]; then
    log_success "PASS: Windows resolves WinGet uv ahead of Chocolatey"
else
    log_error "FAIL: uv resolution: ${uv_resolve_out}"
    failures=$((failures + 1))
fi
if [[ -f "${uv_fake}/home/.config/nvim/venv/nvim-python/MARKER" ]] \
    && ! grep -E '^PKG venv([[:space:]]|$)' "${UV_CALL_LOG}" >/dev/null \
    && ! grep -F 'CHOCO' "${UV_CALL_LOG}" >/dev/null \
    && ! grep -F 'LINK' "${UV_CALL_LOG}" >/dev/null; then
    log_success "PASS: existing venv/nvim-python is not recreated"
else
    log_error "FAIL: venv recreate check marker=$(cat "${uv_fake}/home/.config/nvim/venv/nvim-python/MARKER" 2>/dev/null || echo missing) calls=$(cat "${UV_CALL_LOG}")"
    failures=$((failures + 1))
fi
linux_uv_out="$(
    unset -f uv
    HOME="${uv_fake}/home"
    LOCALAPPDATA="${uv_fake}"
    PLATFORM="linux"
    PATH="${uv_fake}/chocolatey/bin:/usr/bin:/bin"
    hash -r
    : > "${UV_CALL_LOG}"
    prefer_windows_winget_uv
    command -v uv
    uv --version
)"
if [[ "${linux_uv_out}" == *"chocolatey"* && "${linux_uv_out}" != *"astral-sh.uv"* && "${linux_uv_out}" != *"WinGet"* ]]; then
    log_success "PASS: non-Windows does not prepend WinGet uv"
else
    log_error "FAIL: non-Windows uv path: ${linux_uv_out}"
    failures=$((failures + 1))
fi
if grep -F 'CHOCO' "${UV_CALL_LOG}" >/dev/null && ! grep -E 'PKG|LINK' "${UV_CALL_LOG}" >/dev/null; then
    log_success "PASS: non-Windows uv command stays on the non-WinGet binary"
else
    log_error "FAIL: non-Windows uv calls: $(cat "${UV_CALL_LOG}")"
    failures=$((failures + 1))
fi
mnt_uv_out="$(
    unset -f uv
    PLATFORM="windows"
    LOCALAPPDATA="/mnt/c/Users/example/AppData/Local"
    PATH="${uv_fake}/chocolatey/bin:/usr/bin:/bin"
    hash -r
    : > "${UV_CALL_LOG}"
    prefer_windows_winget_uv
    command -v uv
)"
if [[ "${mnt_uv_out}" == *"chocolatey"* && "${mnt_uv_out}" != *"/mnt/c/"* ]]; then
    log_success "PASS: Windows uv lookup skips /mnt/c WinGet paths"
else
    log_error "FAIL: /mnt/c uv lookup: ${mnt_uv_out}"
    failures=$((failures + 1))
fi
rm -rf "${uv_fake}"
unset UV_CALL_LOG

appdata_ready="$(
    PLATFORM="windows"
    APPDATA="/tmp/example-roaming"
    unset FNM_DIR
    cmd() { printf 'CMD_SHOULD_NOT_RUN\n'; }
    _windows_prepare_fnm_dir
    printf 'APPDATA=%s\nFNM_DIR=%s\n' "${APPDATA}" "${FNM_DIR:-}"
)"
assert_eq "already-expanded APPDATA is kept" "APPDATA=/tmp/example-roaming
FNM_DIR=/tmp/example-roaming/fnm" "${appdata_ready}"
appdata_literal="$(
    PLATFORM="windows"
    APPDATA='%APPDATA%'
    unset FNM_DIR
    cmd() { printf '%s\n' 'C:/Users/example/AppData/Roaming'; }
    _windows_prepare_fnm_dir
    printf 'APPDATA=%s\nFNM_DIR=%s\n' "${APPDATA}" "${FNM_DIR:-}"
)"
assert_eq "literal APPDATA expands via cmd" "APPDATA=C:/Users/example/AppData/Roaming
FNM_DIR=C:/Users/example/AppData/Roaming/fnm" "${appdata_literal}"

if _node_version_satisfies_nvim_policy "v24.9.0" \
    && _node_version_satisfies_nvim_policy "v24.11.1" \
    && _node_version_satisfies_nvim_policy "v26.13.0" \
    && ! _node_version_satisfies_nvim_policy "v22.22.3" \
    && ! _node_version_satisfies_nvim_policy "v24.0.0" \
    && ! _node_version_satisfies_nvim_policy "v24.8.0" \
    && ! _node_version_satisfies_nvim_policy "v23.1.0" \
    && ! _node_version_satisfies_nvim_policy "v18.20.0"; then
    log_success "PASS: node policy is >=24.9.0"
else
    log_error "FAIL: node version policy"
    failures=$((failures + 1))
fi
if grep -F 'fnm install lts' "${DEPS_DIR}/install_node.sh" >/dev/null; then
    log_error "FAIL: install_node.sh still runs fnm install lts"
    failures=$((failures + 1))
else
    log_success "PASS: install_node.sh does not run fnm install lts"
fi
if grep -F '22.22.3' "${DEPS_DIR}/install_node.sh" >/dev/null; then
    log_error "FAIL: install_node.sh hardcodes 22.22.3"
    failures=$((failures + 1))
else
    log_success "PASS: install_node.sh does not hardcode 22.22.3"
fi
win_node="$(declare -f _ensure_node_windows)"
if [[ "${win_node}" == *"fnm install"* || "${win_node}" == *"fnm alias"* || "${win_node}" == *'fnm default "'* ]]; then
    log_error "FAIL: Windows node setup installs or changes the fnm alias"
    failures=$((failures + 1))
else
    log_success "PASS: Windows node setup only uses the existing fnm default"
fi
non_win_node="$(declare -f _ensure_node_non_windows)"
if [[ "${non_win_node}" == *"AppData"* || "${non_win_node}" == *"WinGet"* || "${non_win_node}" == *"/mnt/c"* || "${non_win_node}" == *"lts/"* ]]; then
    log_error "FAIL: non-Windows node install references Windows paths"
    failures=$((failures + 1))
else
    log_success "PASS: non-Windows node install has no Windows fnm paths"
fi
if grep -E 'WinGet|/mnt/c' "${DEPS_DIR}/install_python.sh" >/dev/null; then
    log_error "FAIL: install_python.sh references WinGet paths"
    failures=$((failures + 1))
else
    log_success "PASS: install_python.sh does not reference WinGet paths"
fi
macos_uv_fn="$(declare -f _upgrade_uv_macos)"
if [[ "${macos_uv_fn}" == *"WinGet"* || "${macos_uv_fn}" == *"/mnt/c"* || "${macos_uv_fn}" == *"brew "* ]]; then
    log_error "FAIL: macOS uv upgrade references WinGet or brew: ${macos_uv_fn}"
    failures=$((failures + 1))
else
    log_success "PASS: macOS uv upgrade stays on the official updater"
fi

PLATFORM="${_saved_platform_fix}"
PKG_MANAGER="${_saved_pkg_fix}"
PATH="${_saved_path_fix}"
if [[ -n "${_saved_appdata_fix}" ]]; then
    APPDATA="${_saved_appdata_fix}"
else
    unset APPDATA
fi
if [[ -n "${_saved_localappdata_fix}" ]]; then
    LOCALAPPDATA="${_saved_localappdata_fix}"
else
    unset LOCALAPPDATA
fi
if [[ -n "${_saved_fnm_dir_fix}" ]]; then
    FNM_DIR="${_saved_fnm_dir_fix}"
else
    unset FNM_DIR
fi
hash -r

log_info "=== syntax check deps ==="
for f in "${DEPS_DIR}"/*.sh; do
    bash -n "${f}" || failures=$((failures + 1))
done
bash -n "${NVIM_ROOT}/install.sh" || failures=$((failures + 1))
bash -n "${NVIM_ROOT}/scripts/windows_config.sh" || failures=$((failures + 1))
bash -n "${NVIM_ROOT}/scripts/headless_validate.sh" || failures=$((failures + 1))

log_info "=== headless checkhealth ignores dumb-terminal graphics protocol ==="
headless_ignore="$(sed -n "s/^HEADLESS_ERROR_IGNORE='\\(.*\\)'/\\1/p" "${NVIM_ROOT}/scripts/headless_validate.sh")"
headless_fixture="$(mktemp)"
cat > "${headless_fixture}" <<'EOF'
- ❌ ERROR Graphics protocol: not supported by this terminal.
- ❌ ERROR something else broke
EOF
graphics_left="$(grep -iE '^- ERROR|^- ❌ ERROR' "${headless_fixture}" | grep -viE "${headless_ignore}" || true)"
rm -f "${headless_fixture}"
assert_eq "headless keeps real ERROR" "- ❌ ERROR something else broke" "${graphics_left}"

if [[ ${failures} -gt 0 ]]; then
    log_error "test_deps: ${failures} failure(s)"
    exit 1
fi
log_success "test_deps: all passed"
