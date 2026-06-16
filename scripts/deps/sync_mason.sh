#!/usr/bin/env bash
# Headless Mason 预同步

NVIM_MASON_SYNC_STATUS="skipped"

_sync_mason_run_nvim() {
    local config_root="${1:-${NVIM_CONFIG_DIR:-}}"
    shift || true
    [[ -n "${config_root}" ]] || return 1
    [[ -f "${config_root}/init.lua" ]] || return 1

    export MSYS2_ARG_CONV_EXCL="${MSYS2_ARG_CONV_EXCL:-*}"
    export USERPROFILE="${USERPROFILE:-}"
    export LOCALAPPDATA="${LOCALAPPDATA:-}"
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-}"
    export APPDATA="${APPDATA:-}"
    export NVIM_HEADLESS_VALIDATE=1
    unset VIRTUAL_ENV
    if [[ -n "${NVIM_VENV_BIN_DIR:-}" ]] && [[ -d "${NVIM_VENV_BIN_DIR}" ]]; then
        export PATH="${NVIM_VENV_BIN_DIR}:${PATH}"
    fi
    cd "${config_root}" || return 1
    nvim --headless -u init.lua "$@"
}

sync_mason_packages() {
    NVIM_MASON_SYNC_STATUS="skipped"

    if [[ "${NVIM_SKIP_MASON:-1}" == "1" ]]; then
        log_info "Mason sync skipped (default); packages install on first nvim startup (mason-tool-installer + mason-lspconfig)"
        NVIM_MASON_SYNC_STATUS="deferred"
        return 0
    fi

    if ! command -v nvim >/dev/null 2>&1; then
        log_info "Mason sync skipped: nvim not in PATH"
        return 0
    fi

    if ! is_nvim_version_ge_0_11; then
        log_info "Mason sync skipped: Neovim < 0.11.0"
        return 0
    fi

    if [[ ! -f "${NVIM_CONFIG_DIR}/init.lua" ]]; then
        log_info "Mason sync skipped: init.lua not found"
        return 0
    fi

    local mason_packages=()
    local pkg
    while IFS= read -r pkg; do
        [[ -n "${pkg}" ]] && mason_packages+=("${pkg}")
    done < <(nvim_mason_all_packages)

    if [[ ${#mason_packages[@]} -eq 0 ]]; then
        log_warning "Mason sync: empty package list"
        return 0
    fi

    local mason_wait_ms="${NVIM_MASON_WAIT_MS:-600000}"
    local config_root="${NVIM_CONFIG_DIR}"
    local lua_sync="${config_root}/scripts/deps/mason_sync.lua"

    if [[ ! -f "${lua_sync}" ]]; then
        log_warning "Mason sync script not found: ${lua_sync}"
        record_failed "mason sync"
        return 0
    fi

    log_info "Mason sync: installing ${#mason_packages[@]} packages via mason-tool-installer (max wait ${mason_wait_ms}ms)..."

    export NVIM_MASON_PKG_LIST="${mason_packages[*]}"
    export NVIM_MASON_WAIT_MS="${mason_wait_ms}"

    fnm_env_safe

    local mason_rc=0
    if _sync_mason_run_nvim "${config_root}" -c "luafile scripts/deps/mason_sync.lua"; then
        :
    else
        mason_rc=$?
    fi

    unset NVIM_MASON_PKG_LIST NVIM_MASON_WAIT_MS

    if [[ ${mason_rc} -eq 0 ]]; then
        log_success "Mason sync completed"
        NVIM_MASON_SYNC_STATUS="ok"
    else
        log_warning "Mason sync failed (exit ${mason_rc}); packages will install on first Neovim startup"
        NVIM_MASON_SYNC_STATUS="failed"
        record_failed "mason sync"
    fi
}
