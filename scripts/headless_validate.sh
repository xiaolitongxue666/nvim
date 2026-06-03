#!/usr/bin/env bash
# 无头验收：Lazy update + checkhealth + 务实 grep（Win10/Win11 / macOS / Linux 通用）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMMON_LIB="${SCRIPT_DIR}/common.sh"
# shellcheck disable=SC1090
source "${COMMON_LIB}"

CHECKHEALTH_LOG="docs/nvim_checkhealth_final.log"

ensure_windows_user_env
setup_headless_proxy
cleanup_legacy_packer

if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd)" || true
fi

cd "${NVIM_ROOT}"

run_nvim() {
    # Git Bash 勿转换 Windows 环境变量路径
    export MSYS2_ARG_CONV_EXCL="${MSYS2_ARG_CONV_EXCL:-*}"
    export USERPROFILE="${USERPROFILE:-}"
    export LOCALAPPDATA="${LOCALAPPDATA:-}"
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-}"
    export APPDATA="${APPDATA:-}"
    nvim --headless -u init.lua "$@"
}

start_script "Headless Validation"

if [[ "${NVIM_SKIP_LAZY_UPDATE:-1}" != "1" ]]; then
    log_info "=== Lazy update (+ Mason wait) ==="
    run_nvim \
      -c "Lazy! update" \
      -c "sleep 90" \
      -c "qa!"
else
    log_info "Skipping Lazy update (set NVIM_SKIP_LAZY_UPDATE=0 for full sync)"
fi

if [[ "${NVIM_SKIP_LAZY_UPDATE:-1}" != "1" ]] && command -v make >/dev/null 2>&1; then
    log_info "=== Lazy build LuaSnip (jsregexp) ==="
    run_nvim \
      -c "Lazy! build LuaSnip" \
      -c "qa!" || log_warning "LuaSnip build skipped or failed (optional jsregexp)"
fi

log_info "=== checkhealth ==="
run_nvim \
  -c "lua vim.wait(25000, function() return pcall(require,'nvim-treesitter.configs') end)" \
  -c "checkhealth" \
  -c "set buftype=" \
  -c "write! ${CHECKHEALTH_LOG}" \
  -c "qa!"

log_info "=== grep validation (pragmatic) ==="
# 严格：ERROR / ❌
if grep -iE '^- ERROR|❌' "${CHECKHEALTH_LOG}"; then
    log_error "checkhealth contains ERROR"
    exit 1
fi

# 可修复 WARNING（非白名单）
FIXABLE=0
while IFS= read -r line; do
    case "${line}" in
        *"found existing packages at"*) FIXABLE=1 ;;
        *"packer.backup."*) FIXABLE=1 ;;
    esac
done < <(grep -iE '^- WARNING|⚠' "${CHECKHEALTH_LOG}" || true)

if [[ ${FIXABLE} -eq 1 ]]; then
    log_error "checkhealth contains fixable WARNING (packer residue)"
    grep -iE '^- WARNING|⚠' "${CHECKHEALTH_LOG}" || true
    exit 1
fi

# 白名单 WARNING（headless/dumb 终端或可选依赖）仅提示
WHITELIST_LINES=0
while IFS= read -r line; do
    case "${line}" in
        *"Slow shell invocation"*) WHITELIST_LINES=$((WHITELIST_LINES + 1)) ;;
        *"key_backspace"*|*"key_dc"*) WHITELIST_LINES=$((WHITELIST_LINES + 1)) ;;
        *"jsregexp"*) WHITELIST_LINES=$((WHITELIST_LINES + 1)) ;;
        *"Missing user config file: %USERPROFILE%"*) WHITELIST_LINES=$((WHITELIST_LINES + 1)) ;;
    esac
done < <(grep -iE '^- WARNING|⚠' "${CHECKHEALTH_LOG}" || true)

if [[ ${WHITELIST_LINES} -gt 0 ]]; then
    log_info "Known optional/headless WARNINGs present (${WHITELIST_LINES} line(s)); see TROUBLE_SHOOT.md"
fi

log_success "Pragmatic validation passed (no ERROR; no fixable WARNING)"
log_info "Log: ${CHECKHEALTH_LOG}"
end_script
