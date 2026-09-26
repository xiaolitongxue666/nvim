#!/usr/bin/env bash

# Neovim 配置安装脚本
# 支持 macOS、Linux、Windows、WSL；独立仓库
# 使用 uv 管理 Python 环境，使用 fnm 管理 Node.js 环境
# 前置：uv/fnm 官方安装器、Neovim >= 0.11、rustup；依赖见 scripts/deps/manifest.sh

# 启用严格模式：遇到错误立即退出，未定义变量报错，管道中任一命令失败则整个管道失败
set -euo pipefail
# 设置默认文件权限掩码
umask 022

# 本仓库根目录（安装脚本所在目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 通用脚本库：优先环境变量（父项目注入），否则本仓库 scripts/
COMMON_LIB="${COMMON_LIB:-${SCRIPT_DIR}/scripts/common.sh}"
if [[ -f "${COMMON_LIB}" ]]; then
    # shellcheck disable=SC1090
    source "${COMMON_LIB}"
else
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] $*"; }
    log_warning() { echo "[WARNING] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
    error_exit() { log_error "$1"; exit "${2:-1}"; }
    start_script() { echo ""; echo "========== $1 =========="; echo ""; }
    end_script() { echo ""; echo "========== Done =========="; echo ""; }
    ensure_directory() { [[ -n "$1" ]] && [[ ! -d "$1" ]] && mkdir -p "$1"; }
    run_with_timeout() {
        local seconds="$1"
        shift
        if command -v timeout >/dev/null 2>&1; then timeout "${seconds}" "$@"; else "$@"; fi
    }
    windows_path_to_unix() {
        local p="$1"
        p="${p//\\//}"
        if [[ "$p" =~ ^/([a-zA-Z])/(.*)$ ]]; then
            printf '/%s/%s\n' "${BASH_REMATCH[1],,}" "${BASH_REMATCH[2]}"
        elif [[ "$p" =~ ^([a-zA-Z]):/(.*)$ ]]; then
            printf '/%s/%s\n' "${BASH_REMATCH[1],,}" "${BASH_REMATCH[2]}"
        elif [[ "$p" =~ ^([a-zA-Z]):(.*)$ ]]; then
            printf '/%s/%s\n' "${BASH_REMATCH[1],,}" "${BASH_REMATCH[2]}"
        else
            printf '%s\n' "$p"
        fi
    }
    unix_path_to_windows() {
        local p="$1"
        p="${p//\\//}"
        if [[ "$p" =~ ^/([a-z])/(.*)$ ]]; then
            local drive
            drive="$(printf '%s' "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')"
            printf '%s:\\%s\n' "${drive}" "${BASH_REMATCH[2]//\//\\}"
        else
            printf '%s\n' "$p"
        fi
    }
    is_gitbash_absolute_path() {
        local p="$1"
        [[ "$p" =~ ^/[a-zA-Z]/ ]]
    }
fi

# 检测操作系统
OS="$(uname -s)"
if [[ "${OS}" == "Darwin" ]]; then
    PLATFORM="macos"
elif [[ "${OS}" == "Linux" ]]; then
    PLATFORM="linux"
elif [[ "${OS}" == MINGW* ]] || [[ "${OS}" == MSYS* ]] || [[ "${OS}" == CYGWIN* ]]; then
    PLATFORM="windows"
else
    error_exit "Unsupported operating system: ${OS}"
fi

# 全局变量
NVIM_CONFIG_DIR=""
VENV_PATH=""
VENV_ACTIVATE=""    # venv activate 脚本路径（Windows 为 Scripts/activate，macOS/Linux 为 bin/activate）
VENV_PYTHON=""      # venv 内 python 可执行路径（供 init.lua 与校验用）
NODE_PATH=""
NODE_HOST_PATH=""   # neovim host 脚本路径（g:node_host_prog 应指向此，而非 node 可执行文件）
BACKUP_DIR=""
# 可选安装失败/跳过项（结束时汇总显示）
INSTALL_FAILED_ITEMS=()
record_failed() { INSTALL_FAILED_ITEMS+=("$1"); }

# 总进度与子进度（主步骤 1/TOTAL_MAIN_STEPS，子步骤显示进度条）
readonly TOTAL_MAIN_STEPS=18
progress_step() {
    local current="$1" total="$2" msg="$3"
    log_info "[ $current/$total ] $msg"
}
progress_sub() {
    local current="$1" total="$2" name="$3"
    local pct=0
    [[ $total -gt 0 ]] && pct=$((current * 100 / total))
    local filled=$((pct / 5))
    local bar=""
    for ((i=0;i<20;i++)); do
        [[ $i -lt $filled ]] && bar+="=" || bar+="-"
    done
    log_info "[${bar}] (${current}/${total}) ${name}"
}

# 错误处理：捕获 ERR 信号并记录错误信息
trap 'log_error "Error detected at line ${LINENO}, exiting script"; exit 1' ERR

# 清理函数：在脚本退出时清理临时文件
cleanup() {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        log_info "Script exited with error code: ${exit_code}"
    fi
    trap - EXIT ERR
}

trap cleanup EXIT

# 检查配置完整性（init.lua 或 lua/ 至少存在其一）
check_config_integrity() {
    if [[ ! -f "${SCRIPT_DIR}/init.lua" ]] && [[ ! -d "${SCRIPT_DIR}/lua" ]]; then
        log_error "Configuration incomplete: init.lua or lua/ not found"
        log_info "Please run this script from the root of the nvim config repository."
        exit 1
    fi
    log_success "Configuration integrity check passed"
}


check_submodule() {
    if [[ ! -f "${SCRIPT_DIR}/init.lua" ]] && [[ ! -d "${SCRIPT_DIR}/lua" ]]; then
        log_error "Neovim config directory incomplete (missing init.lua or lua/)"
        log_info "Please clone this repo to your config path, e.g.: git clone <this-repo> ~/.config/nvim"
        exit 1
    fi
    log_success "Neovim config directory check passed"
}

# 前置依赖由 scripts/deps/install_prereqs.sh 的 ensure_prerequisites 处理



# 检测 opencode 可执行路径（按 PLATFORM 分支，供 nvim opencode.nvim 使用）
# 设置全局 OPENCODE_CMD，未检测到则为空
detect_opencode_path() {
    OPENCODE_CMD=""
    if [[ "${PLATFORM}" == "linux" ]] || [[ "${PLATFORM}" == "macos" ]]; then
        if command -v opencode >/dev/null 2>&1; then
            OPENCODE_CMD="$(command -v opencode)"
            log_success "opencode found: ${OPENCODE_CMD}"
        else
            log_info "opencode not found in PATH (optional for AI features)"
        fi
    elif [[ "${PLATFORM}" == "windows" ]]; then
        if command -v opencode >/dev/null 2>&1; then
            OPENCODE_CMD="$(command -v opencode)"
            log_success "opencode found: ${OPENCODE_CMD}"
        else
            log_info "opencode not found in PATH (optional for AI features)"
        fi
    fi
}

# 配置 Neovim 路径（Python、Node.js、opencode）
configure_neovim_paths() {
    log_info "Configuring Neovim paths for Python and Node.js..."

    detect_opencode_path

    local config_file="${NVIM_CONFIG_DIR}/init.lua"
    if [[ ! -f "${config_file}" ]]; then
        log_info "init.lua not found, skipping path configuration"
        return 0
    fi

    # 检查是否已经配置了 Python 路径
    local python_configured=0
    if grep -q "python3_host_prog" "${config_file}" 2>/dev/null; then
        python_configured=1
        log_info "Python path already configured in init.lua"
    fi

    # 检查是否已经配置了 Node.js 路径
    local node_configured=0
    if grep -q "node_host_prog" "${config_file}" 2>/dev/null; then
        node_configured=1
        log_info "Node.js path already configured in init.lua"
    fi

    # 检查是否已经配置了 opencode 路径
    local opencode_configured=0
    if grep -q "opencode_cmd" "${config_file}" 2>/dev/null; then
        opencode_configured=1
        log_info "opencode path already configured in init.lua"
    fi

    # 若 Python、Node、opencode 均无需写入则直接返回
    if [[ ${python_configured} -eq 1 ]] && [[ ${node_configured} -eq 1 ]] && { [[ ${opencode_configured} -eq 1 ]] || [[ -z "${OPENCODE_CMD:-}" ]]; }; then
        log_success "All paths already configured"
        return 0
    fi

    # 创建配置片段
    local config_snippet=""

    if [[ ${python_configured} -eq 0 ]] && [[ -n "${VENV_PYTHON:-}" ]] && [[ -f "${VENV_PYTHON}" ]]; then
        local python_prog_slash="${VENV_PYTHON//\\//}"
        config_snippet="${config_snippet}
-- Python interpreter path (auto-configured by install.sh)
vim.g.python3_host_prog = \"${python_prog_slash}\"
-- Add virtual environment site-packages to pythonpath
local venv_path = \"${VENV_PATH//\\//}\"
vim.opt.pp:prepend(venv_path .. \"/lib/python*/site-packages\")
"
    fi

    if [[ ${node_configured} -eq 0 ]] && [[ -n "${NODE_HOST_PATH:-}" ]] && [[ -f "${NODE_HOST_PATH}" ]]; then
        config_snippet="${config_snippet}
-- Node.js host script path (auto-configured by install.sh; must be path to neovim/bin/cli.js)
vim.g.node_host_prog = \"${NODE_HOST_PATH}\"
"
    fi

    if [[ ${opencode_configured} -eq 0 ]] && [[ -n "${OPENCODE_CMD:-}" ]]; then
        local opencode_escaped="${OPENCODE_CMD//\\/\\\\}"
        opencode_escaped="${opencode_escaped//\"/\\\"}"
        config_snippet="${config_snippet}
-- opencode CLI path (auto-configured by install.sh when found in PATH)
vim.g.opencode_cmd = \"${opencode_escaped}\"
"
    fi

    # 如果配置片段不为空，添加到文件末尾
    if [[ -n "${config_snippet}" ]]; then
        # 在文件末尾添加配置（在最后一个非空行之后）
        {
            echo ""
            echo "-- =========================================="
            echo "-- Auto-configured paths (do not edit manually)"
            echo "-- =========================================="
            echo -n "${config_snippet}"
        } >> "${config_file}"
        log_success "Paths configured in init.lua"
    fi
}

# 检查插件管理器
check_plugin_manager() {
    cleanup_legacy_packer
    log_info "Checking plugin manager..."

    if [[ -f "${NVIM_CONFIG_DIR}/lua/config/lazy.lua" ]]; then
        log_success "lazy.nvim plugin manager detected"
        log_info "Plugins will be automatically installed on first Neovim startup"
    else
        log_info "lazy.nvim not found, checking for vim-plug..."
        local vim_plug_dir="${HOME}/.local/share/nvim/site/autoload"
        if [[ ! -f "${vim_plug_dir}/plug.vim" ]]; then
            log_info "Installing vim-plug..."
            ensure_directory "${vim_plug_dir}"
            if curl -fLo "${vim_plug_dir}/plug.vim" --create-dirs \
                https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim 2>/dev/null; then
                log_success "vim-plug installed"
            else
                log_info "Failed to install vim-plug"
            fi
        else
            log_success "vim-plug already installed"
        fi
    fi
}

# 验证安装
verify_installation() {
    log_info "Verifying installation..."

    local errors=0

    # 验证配置文件目录
    if [[ ! -d "${NVIM_CONFIG_DIR}" ]]; then
        log_error "Configuration directory not found: ${NVIM_CONFIG_DIR}"
        errors=$((errors + 1))
    else
        log_success "Configuration directory exists: ${NVIM_CONFIG_DIR}"
    fi

    # 验证 init.lua
    if [[ ! -f "${NVIM_CONFIG_DIR}/init.lua" ]]; then
        log_error "init.lua not found"
        errors=$((errors + 1))
    else
        log_success "init.lua found"
    fi

    # 验证 Python 环境
    if [[ -n "${VENV_PYTHON:-}" ]] && [[ -f "${VENV_PYTHON}" ]]; then
        log_success "Python environment found: ${VENV_PATH}"
    else
        log_info "Python environment not configured"
    fi

    # 验证 Node.js 环境
    if [[ -n "${NODE_PATH:-}" ]] && command -v node >/dev/null 2>&1; then
        log_success "Node.js environment found: ${NODE_PATH}"
    else
        log_info "Node.js environment not configured"
    fi

    # 验证 lazy.nvim
    if [[ -f "${NVIM_CONFIG_DIR}/lua/config/lazy.lua" ]]; then
        log_success "lazy.nvim configuration found"
    else
        log_info "lazy.nvim configuration not found"
    fi

    if [[ ${errors} -eq 0 ]]; then
        log_success "Installation verification completed"
    else
        log_info "Installation verification found ${errors} issue(s)"
    fi

    if command -v nvim >/dev/null 2>&1; then
        if is_nvim_version_ge_0_11; then
            log_success "Neovim version OK: $(nvim --version 2>&1 | head -n 1)"
        else
            log_warning "Neovim below 0.11.0: $(nvim --version 2>&1 | head -n 1)"
            errors=$((errors + 1))
        fi
        # runtime 完整性：版本号正常但 VIMRUNTIME 缺失（apt 安装中断等）时
        # 启动会报 E5113/E484/E5009；此处提前检出并给出修复指引
        if ! verify_nvim_runtime; then
            errors=$((errors + 1))
        fi
    else
        log_warning "Neovim not found in PATH"
        errors=$((errors + 1))
    fi
}

# 检查并安装 clipboard 工具
install_clipboard_tool() {
    log_info "Checking clipboard tool..."

    # 检查是否已有可用的 clipboard 工具
    local clipboard_available=false
    local clipboard_tool=""

    if [[ "${PLATFORM}" == "macos" ]]; then
        # macOS: 检查 pbcopy 和 pbpaste（系统自带）
        if command -v pbcopy >/dev/null 2>&1 && command -v pbpaste >/dev/null 2>&1; then
            clipboard_available=true
            clipboard_tool="pbcopy/pbpaste"
            log_success "Clipboard tool found: pbcopy/pbpaste (macOS built-in)"
        fi
    elif [[ "${PLATFORM}" == "linux" ]]; then
        # Linux: 检查 xclip 或 xsel
        if command -v xclip >/dev/null 2>&1; then
            clipboard_available=true
            clipboard_tool="xclip"
            log_success "Clipboard tool found: xclip"
        elif command -v xsel >/dev/null 2>&1; then
            clipboard_available=true
            clipboard_tool="xsel"
            log_success "Clipboard tool found: xsel"
        fi
    elif [[ "${PLATFORM}" == "windows" ]]; then
        # Windows: Neovim 通常使用 win32yank 或系统剪贴板 API
        # 检查 win32yank（如果通过包管理器安装）
        if command -v win32yank.exe >/dev/null 2>&1; then
            clipboard_available=true
            clipboard_tool="win32yank"
            log_success "Clipboard tool found: win32yank"
        else
            # Windows 上 Neovim 可能使用系统 API，不需要额外工具
            log_info "Windows clipboard support may use system API (no external tool required)"
            clipboard_available=true
            clipboard_tool="system"
        fi
    fi

    # 如果已有工具，直接返回
    if [[ "${clipboard_available}" == true ]]; then
        return 0
    fi

    # 如果没有工具，尝试安装
    log_info "No clipboard tool found; clipboard registers (\"+ and \"*) will not work."
    log_info "Attempting to install clipboard tool..."

    if [[ "${PLATFORM}" == "linux" ]]; then
        # Linux: 尝试安装 xclip 或 xsel
        if command -v apt-get >/dev/null 2>&1; then
            # Debian/Ubuntu
            log_info "Installing xclip via apt-get (requires sudo)..."
            if sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y xclip >/dev/null 2>&1; then
                log_success "xclip installed successfully"
                clipboard_available=true
                clipboard_tool="xclip"
            else
                log_info "Could not install xclip via apt-get"
                log_info "You can manually install it: sudo apt-get install -y xclip"
            fi
        elif command -v yum >/dev/null 2>&1; then
            # RHEL/CentOS
            log_info "Installing xclip via yum (requires sudo)..."
            if sudo yum install -y xclip >/dev/null 2>&1; then
                log_success "xclip installed successfully"
                clipboard_available=true
                clipboard_tool="xclip"
            else
                log_info "Could not install xclip via yum"
                log_info "You can manually install it: sudo yum install -y xclip"
            fi
        elif command -v pacman >/dev/null 2>&1; then
            # Arch Linux
            log_info "Installing xclip via pacman (requires sudo)..."
            if sudo pacman -S --noconfirm xclip >/dev/null 2>&1; then
                log_success "xclip installed successfully"
                clipboard_available=true
                clipboard_tool="xclip"
            else
                log_info "Could not install xclip via pacman"
                log_info "You can manually install it: sudo pacman -S xclip"
            fi
        elif command -v dnf >/dev/null 2>&1; then
            # Fedora
            log_info "Installing xclip via dnf (requires sudo)..."
            if sudo dnf install -y xclip >/dev/null 2>&1; then
                log_success "xclip installed successfully"
                clipboard_available=true
                clipboard_tool="xclip"
            else
                log_info "Could not install xclip via dnf"
                log_info "You can manually install it: sudo dnf install -y xclip"
            fi
        else
            log_info "No supported package manager found for Linux"
            log_info "Please install xclip or xsel manually:"
            log_info "  Debian/Ubuntu: sudo apt-get install -y xclip"
            log_info "  RHEL/CentOS:   sudo yum install -y xclip"
            log_info "  Arch Linux:    sudo pacman -S xclip"
            log_info "  Fedora:        sudo dnf install -y xclip"
        fi
    elif [[ "${PLATFORM}" == "macos" ]]; then
        # macOS: pbcopy/pbpaste 应该总是可用，如果不可用可能是系统问题
        log_info "pbcopy/pbpaste not found on macOS."
        log_info "Please check your macOS installation."
    elif [[ "${PLATFORM}" == "windows" ]]; then
        # Windows: 可以尝试安装 win32yank，但通常不需要
        log_info "For Windows, you can optionally install win32yank:"
        log_info "  Download from: https://github.com/equalsraf/win32yank/releases"
        log_info "  Or use Chocolatey: choco install win32yank"
    fi

    if [[ "${clipboard_available}" == true ]]; then
        log_success "Clipboard tool is now available: ${clipboard_tool}"
        log_info "Clipboard registers (\"+ and \"*) should work in Neovim"
    else
        log_info "Clipboard tool installation failed or skipped"
        log_info "Clipboard registers (\"+ and \"*) will not work in Neovim"
        log_info "You can install it manually later. See: :help clipboard"
    fi
}

# 安装 TreeSitter parsers
install_treesitter_parsers() {
    log_info "Installing TreeSitter parsers..."

    # 检查 Neovim 是否可用
    if ! command -v nvim >/dev/null 2>&1; then
        log_info "Neovim not found, skipping TreeSitter parser installation"
        log_info "TreeSitter parsers will be installed automatically on first Neovim startup"
        return 0
    fi

    # 检查配置文件是否存在
    if [[ ! -f "${NVIM_CONFIG_DIR}/init.lua" ]]; then
        log_info "Neovim configuration not found, skipping TreeSitter parser installation"
        return 0
    fi

    log_info "Installing TreeSitter parsers: bash, regex"
    log_info "This may take a few minutes..."

    # 使用 nvim --headless 执行 TSInstall 和 TSUpdate
    # 使用 -c 参数直接执行命令，等待插件加载
    log_info "You should manually run TreeSitter installation commands (e.g. :TSUpdate)"

    # 构建命令：使用 timeout 防止卡住，增加等待时间让插件完全加载
    # local nvim_cmd="nvim --headless"
    # local install_commands=(
    #     "-c" "lua vim.wait(5000, function() end)"  # 等待插件管理器加载（增加到5秒）
    #     "-c" "TSInstall bash regex"                 # 安装 bash 和 regex parsers
    #     "-c" "TSUpdate"                             # 更新所有 parsers
    #     "-c" "qa!"                                 # 退出
    # )

    # 执行安装，使用 timeout 防止无限等待（最多等待60秒）
    # log_info "This may take up to 60 seconds..."
    # if timeout 60 ${nvim_cmd} -u "${NVIM_CONFIG_DIR}/init.lua" "${install_commands[@]}" >/dev/null 2>&1; then
    #     log_success "TreeSitter parsers installed successfully"
    # else
    #     local exit_code=$?
    #     if [[ ${exit_code} -eq 124 ]]; then
    #         log_warning "TreeSitter parser installation timed out (took longer than 60 seconds)"
    #     else
    #         log_warning "TreeSitter parser installation may have failed (exit code: ${exit_code})"
    #     fi
    #     log_info "Parsers will be installed automatically on first Neovim startup"
    #     log_info "You can also manually run: nvim -c 'TSInstall bash regex' -c 'TSUpdate' -c 'qa'"
    # fi
}

# 若根目录无 PROJECT_MEMORY.md，则从 docs/PROJECT_MEMORY_LOG.md 生成初始版本
ensure_project_memory_file() {
    local target_dir="$1"
    local memory_file="${target_dir}/PROJECT_MEMORY.md"
    local log_file="${target_dir}/docs/PROJECT_MEMORY_LOG.md"

    if [[ -f "${memory_file}" ]]; then
        return 0
    fi

    if [[ ! -f "${log_file}" ]]; then
        return 1
    fi

    {
        echo "# Project Memory"
        echo ""
        echo "> 权威项目记忆文件。\`install.sh\` 结束时会把本文件同步到 \`CLAUDE.md\`、\`AGENTS.md\`、\`.cursor/rules/project-memory.mdc\`。"
        echo "> 按日期追加的变更日志见 [docs/PROJECT_MEMORY_LOG.md](docs/PROJECT_MEMORY_LOG.md)。"
        echo ""
        sed '1,2d' "${log_file}"
    } > "${memory_file}"
    log_info "Created ${memory_file} from docs/PROJECT_MEMORY_LOG.md"
    return 0
}

# 将 PROJECT_MEMORY.md 同步到单个目录下的 agent 配置入口
sync_project_memory_to_dir() {
    local target_dir="$1"
    local source_file="$2"

    [[ -f "${source_file}" ]] || return 1
    [[ -d "${target_dir}" ]] || return 1

    local synced_at
    synced_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S")"

    {
        echo "# Neovim Config — Claude Project Context"
        echo ""
        echo "> Auto-synced from PROJECT_MEMORY.md by install.sh at ${synced_at}. Edit PROJECT_MEMORY.md instead."
        echo ""
        sed '1,4d' "${source_file}"
    } > "${target_dir}/CLAUDE.md"

    {
        echo "# Neovim Config — Agent Instructions"
        echo ""
        echo "> Auto-synced from PROJECT_MEMORY.md by install.sh at ${synced_at}. Edit PROJECT_MEMORY.md instead."
        echo ""
        sed '1,4d' "${source_file}"
    } > "${target_dir}/AGENTS.md"

    ensure_directory "${target_dir}/.cursor/rules"
    {
        echo "---"
        echo "description: Project memory synced from PROJECT_MEMORY.md"
        echo "alwaysApply: true"
        echo "---"
        echo ""
        echo "# Project Memory"
        echo ""
        echo "> Auto-synced from PROJECT_MEMORY.md by install.sh at ${synced_at}. Full file: PROJECT_MEMORY.md"
        echo ""
        sed '1,4d' "${source_file}"
    } > "${target_dir}/.cursor/rules/project-memory.mdc"

    return 0
}

# 同步 PROJECT_MEMORY.md 到 Cursor / Claude / Codex / DeepSeek-tui 可识别的项目级配置
sync_project_memory() {
    log_info "Syncing PROJECT_MEMORY.md to agent configs..."

    ensure_project_memory_file "${SCRIPT_DIR}" || true
    ensure_project_memory_file "${NVIM_CONFIG_DIR}" || true

    local source_file="${NVIM_CONFIG_DIR}/PROJECT_MEMORY.md"
    if [[ ! -f "${source_file}" ]]; then
        source_file="${SCRIPT_DIR}/PROJECT_MEMORY.md"
    fi

    if [[ ! -f "${source_file}" ]]; then
        log_warning "PROJECT_MEMORY.md not found, skipping agent memory sync"
        return 0
    fi

    local sync_errors=0
    if ! sync_project_memory_to_dir "${NVIM_CONFIG_DIR}" "${source_file}"; then
        sync_errors=$((sync_errors + 1))
    fi
    if [[ "${SCRIPT_DIR}" != "${NVIM_CONFIG_DIR}" ]]; then
        if ! sync_project_memory_to_dir "${SCRIPT_DIR}" "${source_file}"; then
            sync_errors=$((sync_errors + 1))
        fi
    fi

    if [[ ${sync_errors} -gt 0 ]]; then
        log_warning "Project memory sync completed with ${sync_errors} error(s)"
        return 0
    fi

    log_success "Project memory synced to CLAUDE.md, AGENTS.md, .cursor/rules/project-memory.mdc"
    return 0
}

# 打印摘要信息
print_summary() {
    log_info "=========================================="
    log_info "Installation Summary"
    log_info "=========================================="
    log_info "Configuration directory: ${NVIM_CONFIG_DIR}"

    if [[ -n "${BACKUP_DIR:-}" ]]; then
        log_info "Backup location: ${BACKUP_DIR}"
    fi

    if [[ -n "${VENV_PATH:-}" ]]; then
        log_info "Python environment: ${VENV_PATH}"
    fi

    if [[ -n "${NODE_PATH:-}" ]]; then
        log_info "Node.js path: ${NODE_PATH}"
    fi

    if command -v nvim >/dev/null 2>&1; then
        log_info "Neovim: $(nvim --version 2>&1 | head -n 1)"
    fi
    if command -v uv >/dev/null 2>&1; then
        log_info "uv: $(uv --version 2>&1 | head -n 1)"
    fi
    if command -v fnm >/dev/null 2>&1; then
        log_info "fnm: $(fnm --version 2>&1 | head -n 1)"
    fi
    log_info "Mason sync: ${NVIM_MASON_SYNC_STATUS:-skipped}"

    log_info ""
    log_info "Next steps:"
    log_info "1. Start Neovim: nvim"
    log_info "2. If using lazy.nvim, plugins will be automatically installed"
    log_info "3. If using vim-plug, run: :PlugInstall"
    log_info ""
    log_info "To update configuration:"
    log_info "  cd ${NVIM_CONFIG_DIR}"
    log_info "  git pull"
    log_info "  ./install.sh"
    log_info ""
    log_info "Project memory: edit PROJECT_MEMORY.md, then re-run install.sh to sync agent configs."
    log_info ""

    if [[ ${#INSTALL_FAILED_ITEMS[@]} -gt 0 ]]; then
        log_info "Failed/skipped (optional): ${INSTALL_FAILED_ITEMS[*]}"
        log_info "  (None of these are required for core Neovim.)"
        log_info ""
    fi
}

# 主函数
main() {
    start_script "Neovim Configuration Installation"

    setup_default_proxy
    detect_runtime_context

    # Windows：脚本一开始就清理可能存在的 %APPDATA% 并导出已展开的 APPDATA
    if [[ "${PLATFORM}" == "windows" ]]; then
        if [[ -d "${SCRIPT_DIR}/%APPDATA%" ]]; then
            rm -rf "${SCRIPT_DIR}/%APPDATA%"
            log_info "Removed stray %APPDATA% directory from repo (startup)"
        fi
        local early_appdata
        early_appdata="$(get_windows_appdata)"
        if [[ -n "${early_appdata}" ]]; then
            export APPDATA="${early_appdata}"
        fi
    fi

    progress_step 1 "${TOTAL_MAIN_STEPS}" "Checking config directory..."
    check_config_integrity

    normalize_windows_home
    ensure_windows_user_env

    progress_step 2 "${TOTAL_MAIN_STEPS}" "Determining config directory..."
    determine_config_dir

    progress_step 3 "${TOTAL_MAIN_STEPS}" "Setting up Windows config redirect..."
    setup_windows_config_redirect
    setup_gitbash_xdg_config_home

    progress_step 4 "${TOTAL_MAIN_STEPS}" "Ensuring prerequisites (git, uv, fnm)..."
    ensure_prerequisites

    progress_step 5 "${TOTAL_MAIN_STEPS}" "Installing search tools (fd, ripgrep) and Neovim (>= 0.11)..."
    install_search_tools
    install_neovim_binary

    progress_step 6 "${TOTAL_MAIN_STEPS}" "Checking Rust (rustup) and C compiler..."
    ensure_rust_and_c_compiler

    progress_step 7 "${TOTAL_MAIN_STEPS}" "Checking system utilities (git, curl, tar)..."
    install_system_utils

    progress_step 8 "${TOTAL_MAIN_STEPS}" "Checking clipboard tool..."
    install_clipboard_tool

    progress_step 9 "${TOTAL_MAIN_STEPS}" "Backing up existing config..."
    backup_existing_config

    progress_step 10 "${TOTAL_MAIN_STEPS}" "Deploying config files..."
    deploy_config

    progress_step 11 "${TOTAL_MAIN_STEPS}" "Setting up Python environment (uv)..."
    setup_python_environment

    progress_step 12 "${TOTAL_MAIN_STEPS}" "Setting up Node.js environment (fnm)..."
    setup_nodejs_environment

    progress_step 13 "${TOTAL_MAIN_STEPS}" "Configuring Neovim paths..."
    configure_neovim_paths

    progress_step 14 "${TOTAL_MAIN_STEPS}" "Checking plugin manager..."
    check_plugin_manager

    progress_step 15 "${TOTAL_MAIN_STEPS}" "Verifying installation..."
    verify_installation

    progress_step 16 "${TOTAL_MAIN_STEPS}" "TreeSitter parsers..."
    install_treesitter_parsers

    if [[ -n "${VENV_PYTHON:-}" ]]; then
        export NVIM_VENV_BIN_DIR="$(dirname "${VENV_PYTHON}")"
    fi

    progress_step 17 "${TOTAL_MAIN_STEPS}" "Syncing Mason packages..."
    sync_mason_packages

    progress_step 18 "${TOTAL_MAIN_STEPS}" "Syncing project memory to agent configs..."
    sync_project_memory || log_warning "Project memory sync failed, continuing"

    log_info "Installation summary..."
    print_summary

    local skip_headless="${NVIM_SKIP_HEADLESS:-}"
    skip_headless="${skip_headless//$'\r'/}"
    if [[ "${skip_headless}" != "1" ]] && [[ -f "${SCRIPT_DIR}/scripts/headless_validate.sh" ]]; then
        log_info "Running headless validation (set NVIM_SKIP_HEADLESS=1 to skip)..."
        # Windows: 把 venv 的 Scripts/bin 加入 PATH，确保 healthcheck 中裸 python 命令可用
        if [[ -n "${VENV_PYTHON:-}" ]]; then
            export NVIM_VENV_BIN_DIR="$(dirname "${VENV_PYTHON}")"
        fi
        if bash "${SCRIPT_DIR}/scripts/headless_validate.sh"; then
            log_success "Headless validation passed"
        else
            log_warning "Headless validation reported issues (see docs/nvim_checkhealth_final.log)"
        fi
        is_windows_platform && cleanup_stray_appdata_in_dir "${SCRIPT_DIR}"
    fi

    end_script
}

# 加载依赖模块（须在 main 调用之前）
DEPS_LOAD="${SCRIPT_DIR}/scripts/deps/load.sh"
if [[ -f "${DEPS_LOAD}" ]]; then
    # shellcheck source=scripts/deps/load.sh
    source "${DEPS_LOAD}"
else
    log_error "Missing dependency module: ${DEPS_LOAD}"
    exit 1
fi

# 执行主函数
main "$@"