#!/usr/bin/env bash
# fnm、Node、neovim host、tree-sitter CLI
# 跑在 script_tool deploy.sh 之后、agent-config install-tools.sh 之前。
# Windows 只用已展开的 fnm default，不安装、不改 alias。
# 合格线是 >=24.9.0（23 无效）。非 Windows 没有合格版本时才 fnm install 24。

# 有限时的 fnm install。超时结束子进程，不 taskkill bash.exe。
_fnm_install_bounded() {
    local version_spec="${1:-24}"
    local secs="${FNM_INSTALL_TIMEOUT_SECS:-90}"
    local pid waited=0 win_pid="" status=0
    log_info "fnm install ${version_spec} (timeout=${secs}s)..."
    fnm install "${version_spec}" &
    pid=$!
    while kill -0 "$pid" 2>/dev/null; do
        if [[ "$waited" -ge "$secs" ]]; then
            log_warning "fnm install timed out after ${secs}s."
            if [[ -r "/proc/${pid}/winpid" ]]; then
                win_pid="$(tr -d '[:space:]' < "/proc/${pid}/winpid" 2>/dev/null || true)"
            fi
            if [[ -n "$win_pid" ]] && command -v taskkill.exe >/dev/null 2>&1; then
                taskkill.exe //F //T //PID "$win_pid" >/dev/null 2>&1 || true
            fi
            kill -9 "$pid" 2>/dev/null || true
            wait "$pid" 2>/dev/null || true
            return 1
        fi
        if [[ "$waited" -gt 0 && $((waited % 15)) -eq 0 ]]; then
            log_info "fnm install still running (${waited}s/${secs}s)..."
        fi
        sleep 1
        waited=$((waited + 1))
    done
    wait "$pid" || status=$?
    return "${status}"
}

# >=24.9.0。major 23 无效。24.0–24.8 不够。
_node_version_satisfies_nvim_policy() {
    local raw="${1:-}"
    local major="" minor="" patch=""
    if [[ "${raw}" =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
        patch="${BASH_REMATCH[3]}"
    elif [[ "${raw}" =~ ([0-9]+)\.([0-9]+) ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
        patch="0"
    else
        return 1
    fi
    if [[ "${major}" -eq 23 ]]; then
        return 1
    fi
    if [[ "${major}" -gt 24 ]]; then
        return 0
    fi
    if [[ "${major}" -eq 24 ]]; then
        if [[ "${minor}" -gt 9 ]]; then
            return 0
        fi
        if [[ "${minor}" -eq 9 && "${patch}" -ge 0 ]]; then
            return 0
        fi
    fi
    return 1
}

# 非 Windows：拒绝 /mnt 上的 Windows node。不读取 WinGet / AppData。
_node_belongs_to_this_environment() {
    local node_path=""
    node_path="$(command -v node 2>/dev/null || true)"
    [[ -n "${node_path}" ]] || return 1
    case "${node_path}" in
        /mnt/c/*|/mnt/C/*|/mnt/host/*|/mnt/wslg/*)
            return 1
            ;;
    esac
    return 0
}

# stdout 为 default 别名的版本号；没有则空。不写 alias 文件。
_fnm_default_version() {
    local line=""
    line="$(fnm list 2>/dev/null | grep 'default' | head -n 1 || true)"
    if [[ "${line}" =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        printf '%s.%s.%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
    fi
}

# Windows：展开 APPDATA，并把 FNM_DIR 指到该用户的 Roaming fnm。不调用 PowerShell。
_windows_prepare_fnm_dir() {
    [[ "${PLATFORM}" == "windows" ]] || return 0
    local val="${APPDATA:-}"
    if [[ -z "${val}" || "${val}" == *"%"* ]]; then
        if ! command -v cmd >/dev/null 2>&1; then
            log_error "cmd not available; cannot expand APPDATA for fnm"
            return 1
        fi
        val="$(MSYS2_ARG_CONV_EXCL='*' cmd //c echo %APPDATA% 2>/dev/null | tr -d '\r\n' || true)"
    fi
    val="${val//[$'\r\n']}"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"
    if [[ -z "${val}" || "${val}" == *"%"* ]]; then
        log_error "Could not expand APPDATA; refusing to run fnm against a literal %APPDATA% directory"
        return 1
    fi
    export APPDATA="${val}"
    if [[ "${val}" == *\\* ]]; then
        export FNM_DIR="${val}\\fnm"
    else
        export FNM_DIR="${val}/fnm"
    fi
    return 0
}

_init_fnm_env() {
    if [[ "${PLATFORM}" == "windows" ]]; then
        if command -v fnm >/dev/null 2>&1; then
            eval "$(fnm env --use-on-cd)" || return 1
            return 0
        fi
        if [[ -x "${HOME}/.local/share/fnm/fnm" ]]; then
            eval "$("${HOME}/.local/share/fnm/fnm" env --use-on-cd)" || return 1
            return 0
        fi
        log_error "fnm not found"
        return 1
    fi
    if [[ -x "${HOME}/.local/share/fnm/fnm" ]]; then
        if eval "$("${HOME}/.local/share/fnm/fnm" env --use-on-cd)"; then
            return 0
        fi
        log_info "Fnm user dir failed, trying system path"
    fi
    eval "$(fnm env --use-on-cd)"
}

# 读 $HOME/.node-version。没有文件则空。
_node_version_file_value() {
    local home="${HOME:-}"
    [[ -n "${home}" && -f "${home}/.node-version" ]] || return 0
    tr -d '\r\n' < "${home}/.node-version" | sed 's/^v//'
}

# 非 Windows：版本文件缺失或低于 24.9 时写成这次的版本，并 fnm default。已合格则不覆盖。
_node_record_pin_if_needed() {
    local ver="${1:-}"
    local home="${HOME:-}"
    local recorded=""
    ver="${ver#v}"
    _node_version_satisfies_nvim_policy "${ver}" || return 1
    case "${home}" in
        ""|/mnt/*)
            log_error "Refusing to write .node-version under ${home:-<empty>}"
            return 1
            ;;
    esac
    recorded="$(_node_version_file_value)"
    if _node_version_satisfies_nvim_policy "${recorded}"; then
        log_info "Keeping ${home}/.node-version at ${recorded}"
        return 0
    fi
    printf '%s\n' "${ver}" > "${home}/.node-version"
    if ! fnm default "${ver}"; then
        fnm alias default "${ver}" || true
    fi
    log_info "Recorded Node.js ${ver} for this environment"
}

# Windows：fnm use default。Win10 与 Win11 同一分支。不安装、不改 alias，不读 WSL 的 fnm。
_ensure_node_windows() {
    local current_version=""
    log_info "Using the existing fnm default Node.js"
    if ! fnm use default; then
        log_error "fnm use default failed"
        exit 1
    fi
    current_version="$(node --version 2>/dev/null || true)"
    if ! _node_version_satisfies_nvim_policy "${current_version}"; then
        log_error "fnm default Node.js ${current_version:-missing} is below 24.9.0. Re-run script_tool deploy.sh in this Windows environment."
        exit 1
    fi
    log_success "Node.js default ready: ${current_version}"
}

# 非 Windows：已有 >=24.9 则保留。没有则 fnm install 24。拒绝 /mnt 上的 Windows node。
_ensure_node_non_windows() {
    local current_version="" default_version="" installed=""
    if _node_belongs_to_this_environment; then
        current_version="$(node --version 2>/dev/null || true)"
        if _node_version_satisfies_nvim_policy "${current_version}"; then
            log_info "Node.js ${current_version} already satisfies >=24.9.0; skipping install"
            return 0
        fi
    fi
    default_version="$(_fnm_default_version)"
    if [[ -n "${default_version}" ]] && _node_version_satisfies_nvim_policy "${default_version}"; then
        log_info "Activating existing fnm default Node.js ${default_version}"
        if fnm use default; then
            log_success "Node.js default ready: $(node --version 2>/dev/null || echo "${default_version}")"
            return 0
        fi
        log_error "fnm use default failed"
        exit 1
    fi
    log_info "Installing Node.js 24 via fnm"
    if _fnm_install_bounded "24"; then
        installed="$(fnm list 2>/dev/null | grep -oE 'v?24\.[0-9]+\.[0-9]+' | sed 's/^v//' | sort -t. -k1,1n -k2,2n -k3,3n | tail -n 1 || true)"
        [[ -n "${installed}" ]] || installed="24"
        if ! fnm use "${installed}"; then
            log_error "Failed to activate Node.js ${installed}"
            exit 1
        fi
        current_version="$(node --version 2>/dev/null || true)"
        if ! _node_version_satisfies_nvim_policy "${current_version}"; then
            log_error "Installed Node.js ${current_version:-missing} is below 24.9.0"
            exit 1
        fi
        _node_record_pin_if_needed "${current_version#v}" || true
        log_success "Node.js ${current_version} ready"
        return 0
    fi
    if _node_belongs_to_this_environment && command -v node >/dev/null 2>&1 \
        && _node_version_satisfies_nvim_policy "$(node --version 2>/dev/null || true)"; then
        log_warning "fnm install 24 failed; using existing node: $(node --version 2>&1)"
        return 0
    fi
    log_error "Failed to install Node.js 24"
    exit 1
}

# 设置 Node.js 环境（使用 fnm 管理）
setup_nodejs_environment() {
    log_info "Setting up Node.js environment with fnm..."

    # Windows：先展开 APPDATA / FNM_DIR，再跑任何 fnm 命令，避免落到字面量 %APPDATA%/fnm
    local _saved_wd="${PWD}"
    if [[ "${PLATFORM}" == "windows" ]]; then
        _windows_prepare_fnm_dir || exit 1
        local _safe_dir=""
        _safe_dir="$(windows_path_to_unix "${APPDATA}")"
        if [[ -d "${_safe_dir}" ]]; then
            cd "${_safe_dir}" || true
        elif [[ -d "${HOME}" ]]; then
            cd "${HOME}" || true
        fi
    fi

    _init_fnm_env || {
        log_error "Failed to initialize fnm environment"
        exit 1
    }

    if [[ "${PLATFORM}" == "windows" ]]; then
        _ensure_node_windows
    else
        _ensure_node_non_windows
    fi

    # 重新初始化 fnm 环境以确保 Node.js 在 PATH 中
    eval "$(fnm env --use-on-cd)" || true

    # 获取 Node.js 路径（优先使用 fnm 稳定路径，避免 fnm_multishells 临时路径在 headless/其他 shell 中失效）
    local fnm_dir="${HOME}/.local/share/fnm"
    if [[ "${PLATFORM}" == "windows" && -n "${FNM_DIR:-}" ]]; then
        fnm_dir="$(windows_path_to_unix "${FNM_DIR}")"
    fi
    NODE_PATH="$(command -v node 2>/dev/null || echo "")"
    if [[ -n "${NODE_PATH}" ]] && [[ "${NODE_PATH}" == *"fnm_multishells"* ]]; then
        local fnm_node_path
        fnm_node_path=$(fnm list 2>/dev/null | grep -E "lts|default" | head -n 1 | awk '{print $2}' || echo "")
        if [[ -n "${fnm_node_path}" ]] && [[ -f "${fnm_dir}/aliases/${fnm_node_path}/bin/node" ]]; then
            NODE_PATH="${fnm_dir}/aliases/${fnm_node_path}/bin/node"
        elif [[ -f "${fnm_dir}/aliases/default/bin/node" ]]; then
            NODE_PATH="${fnm_dir}/aliases/default/bin/node"
        fi
    fi
    if [[ -z "${NODE_PATH}" ]]; then
        local fnm_node_path
        fnm_node_path=$(fnm list 2>/dev/null | grep -E "lts|default" | head -n 1 | awk '{print $2}' || echo "")
        if [[ -n "${fnm_node_path}" ]] && [[ -d "${fnm_dir}/aliases/${fnm_node_path}" ]]; then
            NODE_PATH="${fnm_dir}/aliases/${fnm_node_path}/bin/node"
        elif [[ -f "${fnm_dir}/aliases/default/bin/node" ]]; then
            NODE_PATH="${fnm_dir}/aliases/default/bin/node"
        fi
    fi

    if [[ -n "${NODE_PATH}" ]] && [[ -f "${NODE_PATH}" ]]; then
        log_info "Node.js path: ${NODE_PATH}"
    else
        log_info "Could not determine Node.js path, continuing"
        NODE_PATH=""
    fi

    # Windows：恢复 cwd 到进入 step 10 前的目录，再继续 npm 相关逻辑
    [[ "${PLATFORM}" == "windows" ]] && [[ -n "${_saved_wd:-}" ]] && cd "${_saved_wd}" 2>/dev/null || true

    # 检查 neovim npm 包是否已安装。只看当前环境的 npm prefix。
    if command -v npm >/dev/null 2>&1; then
        local appdata_for_npm=""
        if [[ "${PLATFORM}" == "windows" ]]; then
            if [[ -d "${SCRIPT_DIR}/%APPDATA%" ]]; then
                rm -rf "${SCRIPT_DIR}/%APPDATA%"
                log_info "Removed stray %APPDATA% directory from repo"
            fi
            appdata_for_npm="${APPDATA:-}"
            if [[ -z "${appdata_for_npm}" || "${appdata_for_npm}" == *"%"* ]]; then
                log_info "Could not get Windows APPDATA path, npm may create %APPDATA% in cwd"
                appdata_for_npm=""
            fi
        fi

        # Windows：在 cmd 内用已展开的 APPDATA 跑 npm，避免在项目根下创建 %APPDATA%
        _npm() {
            if [[ "${PLATFORM}" == "windows" && -n "${appdata_for_npm:-}" ]]; then
                local cmd_inner="cd /d \"${appdata_for_npm}\" && set APPDATA=${appdata_for_npm} && npm"
                local a e
                for a in "$@"; do
                    e="${a//\"/\\\"}"
                    cmd_inner="${cmd_inner} \\\"${e}\\\""
                done
                MSYS2_ARG_CONV_EXCL='*' cmd //c "${cmd_inner}"
            elif [[ "${PLATFORM}" == "windows" ]]; then
                MSYS2_ARG_CONV_EXCL='*' npm "$@"
            else
                npm "$@"
            fi
        }
        _npm_cleanup_stray() {
            [[ "${PLATFORM}" != "windows" ]] && return 0
            [[ -d "${SCRIPT_DIR}/%APPDATA%" ]] && rm -rf "${SCRIPT_DIR}/%APPDATA%"
            return 0
        }
        _read_npm_global_root() {
            local root=""
            root="$(_npm root -g 2>/dev/null | tr -d '\r' || true)"
            root="${root##*$'\n'}"
            if declare -F windows_path_to_unix >/dev/null 2>&1; then
                root="$(windows_path_to_unix "${root}")"
            else
                root="${root//\\//}"
            fi
            printf '%s\n' "${root}"
        }

        local npm_global_root=""
        npm_global_root="$(_read_npm_global_root)"
        if [[ -n "${npm_global_root}" && "${npm_global_root}" != *"%"* && -f "${npm_global_root}/neovim/bin/cli.js" ]]; then
            NODE_HOST_PATH="${npm_global_root}/neovim/bin/cli.js"
            log_success "neovim npm package already installed"
            log_info "Neovim node host script: ${NODE_HOST_PATH}"
        else
            if [[ "${PLATFORM}" == "windows" && -n "${appdata_for_npm}" ]]; then
                MSYS2_ARG_CONV_EXCL='*' cmd //c "cd /d \"${appdata_for_npm}\" && set APPDATA=${appdata_for_npm} && npm config set prefix \"${appdata_for_npm}/npm\" --location=user && npm config set cache \"${appdata_for_npm}/npm-cache\" --location=user" || true
            fi
            log_info "Installing neovim npm package..."
            local npm_err="" npm_status=0
            npm_err="$(_npm install -g neovim 2>&1)" || npm_status=$?
            if [[ "${npm_status}" -eq 0 ]]; then
                log_success "neovim npm package installed"
            else
                log_warning "neovim npm package install failed (Python venv remains the host): ${npm_err}"
            fi
            _npm_cleanup_stray
            npm_global_root="$(_read_npm_global_root)"
            if [[ -n "${npm_global_root}" && "${npm_global_root}" != *"%"* && -f "${npm_global_root}/neovim/bin/cli.js" ]]; then
                NODE_HOST_PATH="${npm_global_root}/neovim/bin/cli.js"
                log_info "Neovim node host script: ${NODE_HOST_PATH}"
            elif [[ "${PLATFORM}" == "windows" && -z "${NODE_HOST_PATH:-}" ]]; then
                log_info "Neovim node host path not set (no valid cli.js in npm global)"
            fi
        fi
        _npm_cleanup_stray

        # tree-sitter CLI（建议 >= 0.26.1）
        if command -v tree-sitter >/dev/null 2>&1; then
            log_info "Upgrading tree-sitter CLI..."
            _npm update -g tree-sitter-cli >/dev/null 2>&1 || true
            log_success "tree-sitter CLI ready"
        else
            log_info "Installing tree-sitter CLI (recommended >= 0.26.1)..."
            if _npm install -g tree-sitter-cli >/dev/null 2>&1; then
                log_success "tree-sitter CLI installed"
            else
                log_info "tree-sitter CLI installation failed, continuing"
            fi
        fi
        _npm_cleanup_stray
        if [[ "${PLATFORM}" == "windows" ]] && [[ -d "${SCRIPT_DIR}/%APPDATA%" ]]; then
            rm -rf "${SCRIPT_DIR}/%APPDATA%"
            log_info "Removed stray %APPDATA% directory created by npm"
        fi
    else
        log_info "npm not found, skipping npm package installation"
    fi
}
