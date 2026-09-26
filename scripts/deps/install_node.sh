#!/usr/bin/env bash
# fnm、Node LTS、neovim host、tree-sitter CLI

# 设置 Node.js 环境（使用 fnm 管理）
setup_nodejs_environment() {
    log_info "Setting up Node.js environment with fnm..."

    # Windows：在 fnm/node 检测前 cd 到安全目录（APPDATA 或 HOME），使可能被创建的 %APPDATA% 不落在项目根
    local _saved_wd="${PWD}"
    if [[ "${PLATFORM}" == "windows" ]]; then
        local _safe_dir=""
        local _ad
        _ad="$(get_windows_appdata)"
        if [[ -n "${_ad}" ]]; then
            local _ad_bash="${_ad//\\//}"
            [[ "${_ad_bash}" =~ ^([A-Za-z]):(.*) ]] && _ad_bash="/${BASH_REMATCH[1],,}${BASH_REMATCH[2]}"
            [[ -d "${_ad_bash}" ]] && _safe_dir="${_ad_bash}"
        fi
        [[ -z "${_safe_dir}" ]] && [[ -d "${HOME}" ]] && _safe_dir="${HOME}"
        if [[ -n "${_safe_dir}" ]]; then
            cd "${_safe_dir}" || true
        fi
    fi

    # 初始化 fnm 环境
    # 尝试多种方式初始化 fnm 环境
    if [[ -f "${HOME}/.local/share/fnm/fnm" ]]; then
        # fnm 安装在用户目录
        eval "$("${HOME}/.local/share/fnm/fnm" env --use-on-cd)" || {
            log_info "Fnm user dir failed, trying system path"
            eval "$(fnm env --use-on-cd)" || {
                log_error "Failed to initialize fnm environment"
                exit 1
            }
        }
    else
        # 尝试系统路径
        eval "$(fnm env --use-on-cd)" || {
            log_error "Failed to initialize fnm environment"
            exit 1
        }
    fi

    # 确保 Node.js LTS 为最新（fnm 幂等）
    log_info "Ensuring Node.js LTS via fnm..."
    if fnm install lts/* 2>&1; then
        fnm use lts/* || {
            local installed_lts
            installed_lts=$(fnm list 2>/dev/null | grep -i "lts" | head -n 1 | awk '{print $1}' || echo "")
            if [[ -n "${installed_lts}" ]]; then
                fnm use "${installed_lts}" || {
                    log_error "Failed to activate Node.js version: ${installed_lts}"
                    exit 1
                }
            else
                log_error "Failed to activate Node.js LTS"
                exit 1
            fi
        }
        log_success "Node.js LTS ready: $(node --version 2>/dev/null || echo unknown)"
    else
        if command -v node >/dev/null 2>&1; then
            log_warning "fnm install lts/* failed; using existing node: $(node --version 2>&1)"
        else
            log_error "Failed to install Node.js LTS"
            exit 1
        fi
    fi

    # 重新初始化 fnm 环境以确保 Node.js 在 PATH 中
    eval "$(fnm env --use-on-cd)" || true

    # 获取 Node.js 路径（优先使用 fnm 稳定路径，避免 fnm_multishells 临时路径在 headless/其他 shell 中失效）
    local fnm_dir="${HOME}/.local/share/fnm"
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

    # 检查 neovim npm 包是否已安装
    if command -v npm >/dev/null 2>&1; then
        # Windows：先删误建目录，再取 APPDATA；export 后子进程（npm.cmd 及子进程）才能继承，避免在 cwd 下创建字面量 %APPDATA%
        local appdata_for_npm=""
        local appdata_for_npm_bash=""
        if [[ "${PLATFORM}" == "windows" ]]; then
            if [[ -d "${SCRIPT_DIR}/%APPDATA%" ]]; then
                rm -rf "${SCRIPT_DIR}/%APPDATA%"
                log_info "Removed stray %APPDATA% directory from repo"
            fi
            appdata_for_npm="$(get_windows_appdata)"
            if [[ -n "${appdata_for_npm}" ]]; then
                export APPDATA="${appdata_for_npm}"
                appdata_for_npm_bash="${appdata_for_npm//\\//}"
                [[ "${appdata_for_npm_bash}" =~ ^([A-Za-z]):(.*) ]] && appdata_for_npm_bash="/${BASH_REMATCH[1],,}${BASH_REMATCH[2]}"
                # 在 cmd 内切到 APPDATA 再执行 npm config set，避免在项目根下创建 %APPDATA%
                cmd.exe //c "cd /d \"${appdata_for_npm}\" && set APPDATA=${appdata_for_npm} && npm config set prefix \"${appdata_for_npm}/npm\" --location=user && npm config set cache \"${appdata_for_npm}/npm-cache\" --location=user" 2>/dev/null || true
            else
                log_info "Could not get Windows APPDATA path, npm may create %APPDATA% in cwd"
            fi
        fi

        # Windows：在 cmd 内用 cd /d 切到已展开的 APPDATA 再跑 npm，确保 npm 的 cwd 非项目根，避免在项目根下创建 %APPDATA%
        _npm() {
            if [[ "${PLATFORM}" == "windows" ]] && [[ -n "${appdata_for_npm:-}" ]]; then
                local cmd_inner="cd /d \"${appdata_for_npm}\" && set APPDATA=${appdata_for_npm} && npm"
                local a e
                for a in "$@"; do
                    e="${a//\"/\\\"}"
                    cmd_inner="${cmd_inner} \\\"${e}\\\""
                done
                cmd.exe //c "${cmd_inner}"
            else
                npm "$@"
            fi
        }
        _npm_cleanup_stray() {
            [[ "${PLATFORM}" != "windows" ]] && return 0
            [[ -d "${SCRIPT_DIR}/%APPDATA%" ]] && rm -rf "${SCRIPT_DIR}/%APPDATA%"
            return 0
        }

        if _npm list -g neovim >/dev/null 2>&1; then
            log_info "Upgrading neovim npm package..."
            _npm update -g neovim >/dev/null 2>&1 || _npm install -g neovim >/dev/null 2>&1 || true
            log_success "neovim npm package ready"
        else
            log_info "Installing neovim npm package..."
            if _npm install -g neovim >/dev/null 2>&1; then
                log_success "neovim npm package installed"
            else
                log_info "neovim npm package install failed, continuing"
                log_info "You can install it manually later: npm install -g neovim"
            fi
        fi
        _npm_cleanup_stray
        # g:node_host_prog 需指向 neovim host 脚本（neovim/bin/cli.js）；仅使用展开路径，禁止字面量 %APPDATA%
        local npm_global_root
        npm_global_root="$(_npm root -g 2>/dev/null | tr -d '\r\n')" || true
        npm_global_root="${npm_global_root//\\//}"
        _npm_cleanup_stray
        if [[ "${PLATFORM}" == "windows" ]]; then
            if [[ -z "${npm_global_root}" ]] || [[ "${npm_global_root}" == *%* ]]; then
                if [[ -n "${appdata_for_npm_bash}" ]]; then
                    npm_global_root="${appdata_for_npm_bash}/npm/node_modules"
                fi
            fi
        fi
        if [[ -n "${npm_global_root}" ]] && [[ "${npm_global_root}" != *%* ]] && [[ -f "${npm_global_root}/neovim/bin/cli.js" ]]; then
            NODE_HOST_PATH="${npm_global_root}/neovim/bin/cli.js"
            log_info "Neovim node host script: ${NODE_HOST_PATH}"
        elif [[ "${PLATFORM}" == "windows" ]] && [[ -n "${appdata_for_npm_bash}" ]] && [[ -z "${NODE_HOST_PATH:-}" ]]; then
            log_info "Neovim node host path not set (no valid cli.js in npm global)"
        fi

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

