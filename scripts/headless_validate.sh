#!/usr/bin/env bash
# 无头验收：Lazy update + checkhealth + 务实 grep（Win10/Win11 / macOS / Linux 通用）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMMON_LIB="${SCRIPT_DIR}/common.sh"
# shellcheck disable=SC1090
source "${COMMON_LIB}"

CHECKHEALTH_LOG="docs/nvim_checkhealth_final.log"
# 核心模块验收（跳过 snacks：VeryLazy + 无头 dumb 终端易挂起/误报）
CHECKHEALTH_MODULES="lazy luasnip nvim-treesitter vim.provider vim.lsp vim.health vim.treesitter vim.deprecated"
CHECKHEALTH_TIMEOUT="${NVIM_CHECKHEALTH_TIMEOUT:-90}"

ensure_windows_user_env
setup_headless_proxy
cleanup_legacy_packer

cd "${NVIM_ROOT}"

if is_windows_platform; then
    ensure_windows_appdata_export
    cleanup_stray_appdata_in_dir "${NVIM_ROOT}"
fi

fnm_env_safe

# install.sh 会 export；单独跑本脚本时自动探测 venv Scripts/bin
if [[ -z "${NVIM_VENV_BIN_DIR:-}" ]]; then
    for candidate in \
        "${NVIM_ROOT}/venv/nvim-python/Scripts" \
        "${NVIM_ROOT}/venv/nvim-python/bin"; do
        if [[ -d "${candidate}" ]]; then
            export NVIM_VENV_BIN_DIR="${candidate}"
            break
        fi
    done
fi

run_nvim() {
    # Git Bash 勿转换 Windows 环境变量路径
    export MSYS2_ARG_CONV_EXCL="${MSYS2_ARG_CONV_EXCL:-*}"
    export USERPROFILE="${USERPROFILE:-}"
    export LOCALAPPDATA="${LOCALAPPDATA:-}"
    # 空 XDG_CONFIG_HOME 会使 stdpath('config') 退回相对路径（如 nvim/），
    # 导致 vim.health 误报 Missing user config file；仅非空时导出
    if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then export XDG_CONFIG_HOME; fi
    export APPDATA="${APPDATA:-}"
    export NVIM_HEADLESS_VALIDATE=1
    # 无头模式：persistence_headless_guard 会 persistence.stop()，勿写入 sessions/
    # 无头验收用 g:python3_host_prog，勿继承 shell 的 VIRTUAL_ENV（会触发 vim.provider
    # 对裸 python 的检查；Win10 cmd 子 shell 常无法解析 Git Bash 的 PATH）
    unset VIRTUAL_ENV
    if [[ -n "${NVIM_VENV_BIN_DIR:-}" ]] && [[ -d "${NVIM_VENV_BIN_DIR}" ]]; then
        export PATH="${NVIM_VENV_BIN_DIR}:${PATH}"
    fi
    nvim --headless -u init.lua "$@"
}

# timeout/gtimeout/perl 是外部命令，无法直接执行 shell 函数 run_nvim；
# 用 bash -c 包裹 + declare -f 传递函数体（Win Git Bash / WSL / Linux / macOS 通用），
# 参数经 "$@" 传给子 bash，避免引号丢失。
run_nvim_under_timeout() {
    local seconds="$1"
    shift
    run_with_timeout "${seconds}" bash -c "$(declare -f run_nvim); run_nvim \"\$@\"" _ "$@"
}

# 幂等检查：jsregexp 产物是否已就位（stdpath 解析，跨平台路径兼容）。
# 已编译则跳过 Lazy build —— WSL/Linux 无头下 Lazy! build LuaSnip 完成后
# 退出时会 SIGSEGV（build 本身成功），避免每次全量同步都 core dump。
luasnip_jsregexp_ready() {
    run_nvim \
      -c "lua local f=vim.fn.filereadable(vim.fn.stdpath('data')..'/lazy/LuaSnip/lua/luasnip-jsregexp.lua'); vim.cmd(f==1 and 'cquit 0' or 'cquit 1')" \
      >/dev/null 2>&1
}

start_script "Headless Validation"

if [[ "${NVIM_SKIP_LAZY_UPDATE:-1}" != "1" ]]; then
    log_info "=== Lazy update (+ Mason wait) ==="
    run_nvim_under_timeout 180 \
      -c "Lazy! update" \
      -c "sleep 90" \
      -c "qa!"
else
    log_info "Skipping Lazy update (set NVIM_SKIP_LAZY_UPDATE=0 for full sync)"
fi

if [[ "${NVIM_SKIP_LAZY_UPDATE:-1}" != "1" ]] && command -v make >/dev/null 2>&1; then
    log_info "=== Lazy build LuaSnip (jsregexp) ==="
    if luasnip_jsregexp_ready; then
        log_info "jsregexp already installed; skip rebuild"
    else
        run_nvim \
          -c "Lazy! build LuaSnip" \
          -c "qa!" || log_warning "LuaSnip build skipped or failed (optional jsregexp)"
    fi
fi

log_info "=== checkhealth (modules: ${CHECKHEALTH_MODULES}; timeout ${CHECKHEALTH_TIMEOUT}s) ==="
if ! run_with_timeout "${CHECKHEALTH_TIMEOUT}" bash <<EOF
$(declare -f run_nvim)
run_nvim \\
  -c "lua vim.wait(8000, function() return pcall(require,'nvim-treesitter.configs') end, 50)" \\
  -c "let g:loaded_node_provider=0" \\
  -c "checkhealth ${CHECKHEALTH_MODULES}" \\
  -c "set buftype=" \\
  -c "write! ${CHECKHEALTH_LOG}" \\
  -c "qa!"
EOF
then
    log_error "checkhealth timed out or failed after ${CHECKHEALTH_TIMEOUT}s"
    log_info "If stuck on network: USE_PROXY=0 ./scripts/headless_validate.sh"
    log_info "Or increase: NVIM_CHECKHEALTH_TIMEOUT=180 ./scripts/headless_validate.sh"
    exit 1
fi

log_info "=== grep validation (pragmatic) ==="
# 严格：条目行 ERROR（luasnip 未安装时跳过 No healthcheck found；
# vim.provider 的 PyPI 联网检查在无外网/代理受限/网络波动时必失败，属外部环境问题，白名单）
if grep -iE '^- ERROR|^- ❌ ERROR' "${CHECKHEALTH_LOG}" | grep -viE 'No healthcheck found for "luasnip"|HTTP request failed'; then
    log_error "checkhealth contains ERROR"
    grep -iE '^- ERROR|^- ❌ ERROR' "${CHECKHEALTH_LOG}" | grep -viE 'No healthcheck found for "luasnip"|HTTP request failed' || true
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
        *"No healthcheck found for \"luasnip\""*) WHITELIST_LINES=$((WHITELIST_LINES + 1)) ;;
        *"Could not contact PyPI"*|*"HTTP request failed"*) WHITELIST_LINES=$((WHITELIST_LINES + 1)) ;;
    esac
done < <(grep -iE '^- WARNING|⚠|^- ERROR|^- ❌ ERROR' "${CHECKHEALTH_LOG}" || true)

if [[ ${WHITELIST_LINES} -gt 0 ]]; then
    log_info "Known optional/headless WARNINGs present (${WHITELIST_LINES} line(s)); see TROUBLE_SHOOT.md"
fi

log_success "Pragmatic validation passed (no ERROR; no fixable WARNING)"
log_info "Log: ${CHECKHEALTH_LOG}"
is_windows_platform && cleanup_stray_appdata_in_dir "${NVIM_ROOT}"
end_script
