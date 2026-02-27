#!/usr/bin/env bash

# Neovim 配置安装脚本
# 支持 macOS、Linux、Windows 系统（推荐/测试环境含 Windows 10 + Git Bash）
# 使用 Git Submodule 管理配置
# 前置：uv（管理 Python）、fnm（管理 Node）；各平台均需先安装。
#
# 版本与前置要求（与本仓库配置一致）：
#   - Neovim 0.11.0+（本配置使用 vim.lsp.config、nvim-notify 等 0.11 API）
#   - 升级 Neovim 后建议执行：uv pip install -U pynvim
#   - tree-sitter-cli 建议 >= 0.26.1（nvim-treesitter 可选）
#   - 系统 Lua 为可选：Neovim 运行依赖其内置 LuaJIT，系统 Lua 仅用于部分构建/脚本

# 启用严格模式：遇到错误立即退出，未定义变量报错，管道中任一命令失败则整个管道失败
set -euo pipefail
# 设置默认文件权限掩码
umask 022

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 项目根与通用脚本库：优先使用环境变量（由父项目 run_once 注入）
if [[ -n "${PROJECT_ROOT:-}" ]] && [[ -n "${COMMON_LIB:-}" ]] && [[ -f "${COMMON_LIB}" ]]; then
    :
elif [[ -n "${COMMON_LIB:-}" ]] && [[ -f "${COMMON_LIB}" ]]; then
    PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
else
    PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
    COMMON_LIB="${COMMON_LIB:-${PROJECT_ROOT}/scripts/common.sh}"
fi
# 引入通用日志/错误处理函数；若不存在则使用脚本内最小实现
if [[ -f "${COMMON_LIB:-}" ]]; then
    # shellcheck disable=SC1090
    source "${COMMON_LIB}"
else
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] $*"; }
    log_warning() { echo "[WARNING] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
    error_exit() { log_error "$1"; exit "${2:-1}"; }
    start_script() { echo ""; echo "=========================================="; echo "Starting: $1"; echo "=========================================="; echo ""; }
    end_script() { echo ""; echo "=========================================="; echo "Script execution completed"; echo "=========================================="; echo ""; trap - EXIT; exit 0; }
    ensure_directory() { if [[ ! -d "$1" ]]; then mkdir -p "$1"; log_info "Directory created: $1"; fi; }
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
readonly TOTAL_MAIN_STEPS=15
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

# Windows：规范化 HOME 为 Windows 用户目录的 Unix 形式（如 /c/Users/xxx），
# 避免 MSYS2 等环境下 HOME=/home/xxx 导致配置装到错误目录。仅 PLATFORM=windows 时执行。
normalize_windows_home() {
    [[ "${PLATFORM}" != "windows" ]] && return 0
    local need_export=0
    # 仅当 HOME 未设置、为空或为 MSYS2 风格 /home/* 时才覆盖
    if [[ -z "${HOME:-}" ]] || [[ "${HOME}" == /home/* ]]; then
        local userprofile="${USERPROFILE:-}"
        if [[ -z "${userprofile}" ]]; then
            userprofile=$(cmd //c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r\n' || true)
        fi
        userprofile="${userprofile//[$'\r\n']}"
        userprofile="${userprofile#"${userprofile%%[![:space:]]*}"}"
        userprofile="${userprofile%"${userprofile##*[![:space:]]}"}"
        if [[ -n "${userprofile}" ]]; then
            # 优先手写转换为 /c/Users/xxx（与 Git Bash 一致）；cygpath 在 MSYS2 可能返回 /home/xxx
            if [[ "${userprofile}" =~ ^([A-Za-z]):(.*) ]]; then
                local rest="${BASH_REMATCH[2]//\\//}"
                rest="${rest#/}"
                HOME="/${BASH_REMATCH[1],,}/${rest}"
                need_export=1
            elif command -v cygpath >/dev/null 2>&1; then
                HOME=$(cygpath -u "${userprofile}" 2>/dev/null || true)
                [[ -n "${HOME:-}" ]] && need_export=1
            fi
        fi
        # 备用：从脚本路径推导（脚本在 /c/Users/xxx/.config/nvim 等时，如 Git Bash）
        if [[ ${need_export} -eq 0 ]] && [[ "${SCRIPT_DIR}" =~ ^(/[a-z]/[Uu]sers/[^/]+)/.config/nvim$ ]]; then
            HOME="${BASH_REMATCH[1]}"
            need_export=1
        fi
    fi
    if [[ ${need_export} -eq 1 ]] && [[ -n "${HOME:-}" ]]; then
        export HOME
    fi
}

# Windows：获取已展开的 APPDATA 路径（供 npm 使用，避免 npm 在 cwd 下创建字面量 %APPDATA% 目录）
# 返回 Windows 风格路径（反斜杠），便于 export APPDATA 后子进程正确识别；脚本内路径拼接需再转为正斜杠。
get_windows_appdata() {
    [[ "${PLATFORM}" != "windows" ]] && return 0
    local val=""
    if [[ -n "${APPDATA:-}" ]] && [[ "${APPDATA}" != *%* ]]; then
        val="${APPDATA}"
    fi
    if [[ -z "${val}" ]] && command -v cmd.exe >/dev/null 2>&1; then
        val="$(cmd.exe //c "echo %APPDATA%" 2>/dev/null | tr -d '\r\n' || echo "")"
    fi
    if [[ -z "${val}" ]] && command -v node >/dev/null 2>&1; then
        val="$(node -e "try{const c=require('child_process').execSync('cmd /c echo %APPDATA%',{encoding:'utf8',windowsHide:true}); process.stdout.write((c||'').trim().replace(/\r\n?/g,''))}catch(e){}" 2>/dev/null || echo "")"
    fi
    val="${val//[$'\r\n']}"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"
    [[ -n "${val}" ]] && echo "${val}"
}

# 检查配置目录是否完整（init.lua 或 lua/ 存在）
check_submodule() {
    if [[ ! -f "${SCRIPT_DIR}/init.lua" ]] && [[ ! -d "${SCRIPT_DIR}/lua" ]]; then
        log_error "Neovim config directory incomplete (missing init.lua or lua/)"
        log_info "Please clone this repo to your config path, e.g.: git clone <this-repo> ~/.config/nvim"
        exit 1
    fi
    log_success "Neovim config directory check passed"
}

# 检查前置依赖（uv, fnm；系统 Lua 为可选，Neovim 运行依赖内置 LuaJIT）
check_prerequisites() {
    log_info "Checking prerequisites..."

    # 检查 uv
    if ! command -v uv >/dev/null 2>&1; then
        error_exit "uv is not installed. Please run install_common_tools.sh first to install uv"
    fi
    log_success "uv found: $(uv --version | head -n 1)"

    # 检查 fnm
    if ! command -v fnm >/dev/null 2>&1; then
        error_exit "fnm is not installed. Please run install_common_tools.sh first to install fnm"
    fi
    log_success "fnm found: $(fnm --version)"

    # 检查 Lua（可选：用于部分构建/脚本；Neovim 运行依赖其内置 LuaJIT，不依赖系统 Lua）
    local lua_installed=0
    if command -v lua >/dev/null 2>&1; then
        lua_installed=1
        log_success "Lua found: $(lua -v 2>&1 | head -n 1)"
    elif [[ "${PLATFORM}" == "linux" ]] && command -v pacman >/dev/null 2>&1; then
        if pacman -Qi lua >/dev/null 2>&1; then
            lua_installed=1
            log_success "Lua found via pacman"
        fi
    fi

    if [[ ${lua_installed} -eq 0 ]]; then
        log_info "Lua is not installed (optional for Neovim)"
        record_failed "Lua"
        install_lua
    fi

    log_success "All prerequisites checked"
}

# 检测当前 Rust 是否来自 rustup（~/.cargo/bin），否则视为系统/apt 旧版
is_rust_from_rustup() {
    local r
    r="$(command -v rustc 2>/dev/null)"
    [[ -n "$r" && "$r" == *".cargo"* ]] && return 0
    r="$(command -v cargo 2>/dev/null)"
    [[ -n "$r" && "$r" == *".cargo"* ]] && return 0
    return 1
}

# 使用官网 rustup 安装 Rust 最新稳定版（https://rustup.rs）
install_rust_official() {
    log_info "Installing Rust (official rustup, latest stable)..."
    if ! command -v curl >/dev/null 2>&1; then
        log_info "curl not found; cannot install rustup. Install curl or Rust manually: https://rustup.rs/"
        record_failed "rust"
        return 1
    fi
    local rustup_sh="https://sh.rustup.rs"
    if curl --proto '=https' --tlsv1.2 -sSf "${rustup_sh}" | sh -s -- -y 2>/dev/null; then
        # 当前 shell 加载 cargo 环境以便校验
        if [[ -f "${HOME}/.cargo/env" ]]; then
            # shellcheck source=/dev/null
            source "${HOME}/.cargo/env"
        fi
        if command -v rustc >/dev/null 2>&1; then
            log_success "Rust installed (rustup): $(rustc --version 2>&1 | head -n 1)"
        else
            log_success "Rust (rustup) installed. Add to PATH: source \$HOME/.cargo/env 或重新打开终端"
        fi
    else
        log_info "Rust (rustup) installation failed. Install manually: https://rustup.rs/"
        record_failed "rust"
    fi
}

# 安装语言工具（与 LSP 配置对应：Go, Ruby, Composer, Rust, C/C++ 编译器）
# LSP 对应：lua_ls(Lua→install_lua)、pyright/ruff(Python→setup_python)、rust_analyzer(Rust→官网 rustup)、clangd(C/C++)、bashls/jsonls/yamlls/marksman 无需系统编译器
install_language_tools() {
    log_info "Installing language tools for mason.nvim and LSP..."

    # 定义需要安装的工具
    local tools_to_install=()

    # 检查并安装 Go
    if ! command -v go >/dev/null 2>&1; then
        tools_to_install+=("go")
    else
        log_success "Go already installed: $(go version 2>&1 | head -n 1)"
    fi

    # 检查并安装 Ruby
    if ! command -v ruby >/dev/null 2>&1; then
        tools_to_install+=("ruby")
    else
        log_success "Ruby already installed: $(ruby --version 2>&1 | head -n 1)"
    fi

    # 检查并安装 Composer (PHP)
    # 注：不在此处执行 composer --version，避免因 Composer 自检/网络导致脚本卡住
    if ! command -v composer >/dev/null 2>&1; then
        tools_to_install+=("composer")
    else
        log_success "Composer already installed"
    fi

    # 检查并安装 Rust（对应 LSP: rust_analyzer）。无 Rust 或仅有系统/apt 旧版时均安装官网 rustup 以获最新稳定版
    if ! command -v rustc >/dev/null 2>&1 && ! command -v cargo >/dev/null 2>&1; then
        tools_to_install+=("rust")
    elif ! is_rust_from_rustup; then
        log_info "Rust (system/apt) found, will install official rustup for latest stable: $(command -v rustc 2>/dev/null || true)"
        tools_to_install+=("rust")
    else
        if command -v rustc >/dev/null 2>&1; then
            log_success "Rust already installed (rustup): $(rustc --version 2>&1 | head -n 1)"
        else
            log_success "Cargo already installed (rustup)"
        fi
    fi

    # 检查并安装 C/C++ 编译器（对应 LSP: clangd；Mason 装 clangd，系统编译器用于构建/检查）
    if ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
        tools_to_install+=("c_compiler")
    else
        if command -v gcc >/dev/null 2>&1; then
            log_success "GCC already installed: $(gcc --version 2>&1 | head -n 1)"
        else
            log_success "Clang already installed: $(clang --version 2>&1 | head -n 1)"
        fi
    fi

    # 如果所有工具都已安装，直接返回
    if [[ ${#tools_to_install[@]} -eq 0 ]]; then
        log_success "All language tools are already installed"
        return 0
    fi

    log_info "Tools to install: ${tools_to_install[*]}"

    # 根据操作系统安装工具
    if [[ "${PLATFORM}" == "linux" ]]; then
        # Linux: 使用包管理器
        if command -v pacman >/dev/null 2>&1; then
            # Arch Linux
            local pacman_packages=()
            for tool in "${tools_to_install[@]}"; do
                case "${tool}" in
                    "go")
                        pacman_packages+=("go")
                        ;;
                    "ruby")
                        pacman_packages+=("ruby")
                        ;;
                    "composer")
                        pacman_packages+=("php" "composer")
                        ;;
                    "c_compiler")
                        pacman_packages+=("base-devel")
                        ;;
                esac
            done

            if [[ ${#pacman_packages[@]} -gt 0 ]]; then
                log_info "Installing packages via pacman (requires sudo): ${pacman_packages[*]}"
                if sudo pacman -S --noconfirm "${pacman_packages[@]}" 2>&1; then
                    log_success "Language tools installed successfully"
                else
                    log_info "Some language tools could not be installed via pacman; you can run: sudo pacman -S ${pacman_packages[*]}"
                fi
            fi
        elif command -v apt-get >/dev/null 2>&1; then
            # Debian/Ubuntu：仅安装仓库中存在的包，避免报错；逐包显示进度
            local apt_tool_map=(
                "go:golang-go"
                "ruby:ruby"
                "composer:composer"
                "c_compiler:build-essential"
            )
            local apt_to_install=()
            for entry in "${apt_tool_map[@]}"; do
                local tool_name="${entry%%:*}"
                local pkg_name="${entry##*:}"
                if [[ " ${tools_to_install[*]} " =~ " ${tool_name} " ]]; then
                    apt_to_install+=("${pkg_name}")
                fi
            done
            if [[ ${#apt_to_install[@]} -gt 0 ]]; then
                log_info "Updating apt cache (requires sudo)..."
                sudo apt-get update -qq 2>/dev/null || true
                local total=${#apt_to_install[@]} idx=0
                for pkg_name in "${apt_to_install[@]}"; do
                    idx=$((idx + 1))
                    progress_sub "${idx}" "${total}" "apt-get: ${pkg_name}"
                    if apt-cache show "${pkg_name}" >/dev/null 2>&1; then
                        if sudo apt-get install -y "${pkg_name}" >/dev/null 2>&1; then
                            log_success "Installed ${pkg_name}"
                        else
                            log_info "Skipped ${pkg_name} (install failed)"
                            record_failed "${pkg_name}"
                        fi
                    else
                        log_info "Skipped ${pkg_name} (not in default repos)"
                        record_failed "${pkg_name}"
                    fi
                done
            fi
        elif command -v yum >/dev/null 2>&1; then
            # CentOS/RHEL
            local yum_packages=()
            for tool in "${tools_to_install[@]}"; do
                case "${tool}" in
                    "go")
                        yum_packages+=("golang")
                        ;;
                    "ruby")
                        yum_packages+=("ruby")
                        ;;
                    "composer")
                        yum_packages+=("php-composer")
                        ;;
                    "c_compiler")
                        yum_packages+=("gcc")
                        ;;
                esac
            done

            if [[ ${#yum_packages[@]} -gt 0 ]]; then
                log_info "Installing packages via yum (requires sudo): ${yum_packages[*]}"
                if sudo yum install -y "${yum_packages[@]}" 2>&1; then
                    log_success "Language tools installed successfully"
                else
                    log_info "Some language tools could not be installed via yum; you can run: sudo yum install -y ${yum_packages[*]}"
                fi
            fi
        else
            log_info "No supported package manager found for Linux; please install language tools manually if needed"
        fi
        # Rust 使用官网 rustup 安装最新稳定版（不通过包管理器）
        if [[ " ${tools_to_install[*]} " =~ " rust " ]]; then
            install_rust_official
        fi
    elif [[ "${PLATFORM}" == "macos" ]]; then
        # macOS: 使用 Homebrew
        if command -v brew >/dev/null 2>&1; then
            local brew_packages=()
            for tool in "${tools_to_install[@]}"; do
                case "${tool}" in
                    "go")
                        brew_packages+=("go")
                        ;;
                    "ruby")
                        brew_packages+=("ruby")
                        ;;
                    "composer")
                        brew_packages+=("composer")
                        ;;
                    "c_compiler")
                        brew_packages+=("llvm")
                        ;;
                esac
            done

            if [[ ${#brew_packages[@]} -gt 0 ]]; then
                log_info "Installing packages via Homebrew: ${brew_packages[*]}"
                if brew install "${brew_packages[@]}" 2>&1; then
                    log_success "Language tools installed successfully"
                else
                    log_info "Some language tools could not be installed via Homebrew; you can run: brew install ${brew_packages[*]}"
                fi
            fi
        else
            log_info "Homebrew not found; install language tools manually if needed"
            log_info "Please install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        fi
        # Rust 使用官网 rustup 安装最新稳定版（不通过 Homebrew）
        if [[ " ${tools_to_install[*]} " =~ " rust " ]]; then
            install_rust_official
        fi
    elif [[ "${PLATFORM}" == "windows" ]]; then
        # Windows: 尝试自动安装
        log_info "Windows platform detected, attempting automatic installation..."

        # 代理设置（如果需要）
        local proxy_host="${PROXY_HOST:-127.0.0.1}"
        local proxy_port="${PROXY_PORT:-7890}"
        local use_proxy="${USE_PROXY:-1}"

        if [[ "${use_proxy}" == "1" ]]; then
            export http_proxy="http://${proxy_host}:${proxy_port}"
            export https_proxy="http://${proxy_host}:${proxy_port}"
            export HTTP_PROXY="http://${proxy_host}:${proxy_port}"
            export HTTPS_PROXY="http://${proxy_host}:${proxy_port}"
            export npm_config_proxy="http://${proxy_host}:${proxy_port}"
            export npm_config_https_proxy="http://${proxy_host}:${proxy_port}"
            log_info "Proxy enabled: http://${proxy_host}:${proxy_port}"
        fi

        # 安装 Go
        if [[ " ${tools_to_install[*]} " =~ " go " ]]; then
            log_info "Installing Go..."
            if command -v winget >/dev/null 2>&1; then
                # 检查是否已安装但不在 PATH
                local go_paths=(
                    "/c/Program Files/Go/bin/go"
                    "/c/Program Files (x86)/Go/bin/go"
                    "${HOME}/go/bin/go"
                )
                local go_found=0
                for go_path in "${go_paths[@]}"; do
                    if [[ -f "${go_path}" ]]; then
                        log_info "Found Go at: ${go_path}"
                        export PATH="${PATH}:$(dirname "${go_path}")"
                        go_found=1
                        break
                    fi
                done

                if [[ ${go_found} -eq 0 ]]; then
                    if winget install --id GoLang.Go --silent --accept-package-agreements --accept-source-agreements 2>&1; then
                        log_success "Go installed successfully"
                        export PATH="${PATH}:/c/Program Files/Go/bin"
                    else
                        log_info "Go installation failed; you can install manually: winget install GoLang.Go"
                    fi
                fi
            else
                log_info "winget not found; install Go manually if needed: https://golang.org/dl/"
            fi
        fi

        # 安装 Composer
        if [[ " ${tools_to_install[*]} " =~ " composer " ]]; then
            log_info "Installing Composer..."
            local composer_phar_path="${HOME}/.local/bin/composer"
            local composer_dir="$(dirname "${composer_phar_path}")"
            mkdir -p "${composer_dir}"

            if curl -x "http://${proxy_host}:${proxy_port}" -o "${composer_phar_path}" \
                "https://getcomposer.org/download/latest-stable/composer.phar" 2>&1; then
                chmod +x "${composer_phar_path}"
                if "${composer_phar_path}" --version >/dev/null 2>&1; then
                    log_success "Composer installed successfully (phar)"
                    log_info "Composer path: ${composer_phar_path}"
                    log_info "Please ensure ${composer_dir} is in PATH"
                else
                    log_info "Composer installation verification failed"
                fi
            else
                log_info "Composer download failed; install manually if needed: https://getcomposer.org/download/"
            fi
        fi

        # Ruby 在 Windows 上通常已安装（通过 RubyInstaller），只需检查
        if [[ " ${tools_to_install[*]} " =~ " ruby " ]]; then
            log_info "Checking Ruby installation..."
            if ! command -v ruby >/dev/null 2>&1; then
                log_info "Ruby not found; install manually if needed: https://rubyinstaller.org/ or winget install RubyInstallerTeam.Ruby"
            fi
        fi

        # 安装 Rust（对应 LSP: rust_analyzer）
        if [[ " ${tools_to_install[*]} " =~ " rust " ]]; then
            log_info "Installing Rust..."
            if command -v winget >/dev/null 2>&1; then
                if winget install --id Rustlang.Rustup --silent --accept-package-agreements --accept-source-agreements 2>&1; then
                    log_success "Rust installed successfully (rustup)"
                    log_info "Please restart the terminal or run: \$env:Path = [System.Environment]::GetEnvironmentVariable('Path','User') + ';' + [System.Environment]::GetEnvironmentVariable('Path','Machine')"
                else
                    log_info "Rust installation failed; install manually: winget install Rustlang.Rustup or https://rustup.rs/"
                fi
            else
                log_info "winget not found; install Rust manually: https://rustup.rs/"
            fi
        fi

        # C/C++ 编译器（对应 LSP: clangd；Mason 提供 clangd，系统编译器可选）
        if [[ " ${tools_to_install[*]} " =~ " c_compiler " ]]; then
            log_info "Checking C/C++ compiler..."
            if command -v winget >/dev/null 2>&1; then
                if winget install --id LLVM.LLVM --silent --accept-package-agreements --accept-source-agreements 2>&1; then
                    log_success "LLVM/Clang installed successfully"
                else
                    log_info "C/C++ compiler not found; for clangd LSP you can use Mason. To compile C/C++: install MinGW or Visual Studio Build Tools."
                fi
            else
                log_info "Install MinGW or Visual Studio Build Tools for C/C++ compilation if needed."
            fi
        fi
    fi
}

# 安装 Lua（可选；Neovim 运行不依赖系统 Lua，仅部分构建/脚本可能用到）
install_lua() {
    log_info "Installing Lua..."

    if [[ "${PLATFORM}" == "linux" ]] && command -v pacman >/dev/null 2>&1; then
        log_info "Installing Lua via pacman (requires sudo)"
        if sudo pacman -S --noconfirm lua >/dev/null 2>&1; then
            log_success "Lua installed successfully"
        else
            log_info "Could not install Lua via pacman; install manually if needed"
            log_info "Run: sudo pacman -S lua"
        fi
    elif [[ "${PLATFORM}" == "macos" ]] && command -v brew >/dev/null 2>&1; then
        log_info "Installing Lua via Homebrew"
        if brew install lua >/dev/null 2>&1; then
            log_success "Lua installed successfully"
        else
            log_info "Could not install Lua via Homebrew; install manually if needed"
            log_info "Run: brew install lua"
        fi
    else
        log_info "Cannot automatically install Lua on this platform"
        log_info "Please install Lua manually for your system"
        log_info "Arch Linux: sudo pacman -S lua"
        log_info "macOS: brew install lua"
        log_info "Windows: Download from https://luabinaries.sourceforge.net/"
    fi
}

# 确定配置目录（多 OS 统一：一律使用 $HOME/.config/nvim）
determine_config_dir() {
    NVIM_CONFIG_DIR="${HOME}/.config/nvim"
    log_info "Neovim config directory: ${NVIM_CONFIG_DIR}"
}

# Windows：可选提示设置 XDG_CONFIG_HOME（与 Neovim 行为一致），不影响本脚本的配置目录（已统一为 $HOME/.config/nvim）
check_windows_config() {
    if [[ "${PLATFORM}" == "windows" ]] && [[ -z "${XDG_CONFIG_HOME:-}" ]]; then
        log_info "XDG_CONFIG_HOME not set; config directory is \$HOME/.config/nvim"
        log_info "Optional: set XDG_CONFIG_HOME to match Neovim (e.g. C:\\Users\\<username>\\.config\\) in Environment Variables and restart terminal"
    fi
}

# 备份现有配置
backup_existing_config() {
    # Windows：若 step 1～6 中仍有子进程在项目根下创建了 %APPDATA%，在此处清理，避免用户看到该目录
    if [[ "${PLATFORM}" == "windows" ]] && [[ -d "${SCRIPT_DIR}/%APPDATA%" ]]; then
        rm -rf "${SCRIPT_DIR}/%APPDATA%"
        log_info "Removed stray %APPDATA% directory from repo (before backup)"
    fi
    if [[ -d "${NVIM_CONFIG_DIR}" ]] && [[ -n "$(ls -A "${NVIM_CONFIG_DIR}" 2>/dev/null)" ]]; then
        BACKUP_DIR="${NVIM_CONFIG_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Existing configuration detected, creating backup..."

        if cp -r "${NVIM_CONFIG_DIR}" "${BACKUP_DIR}" 2>/dev/null; then
            log_success "Configuration backed up to: ${BACKUP_DIR}"
        else
            log_info "Backup failed, continuing with installation"
            BACKUP_DIR=""
        fi
    else
        log_info "No existing configuration found, skipping backup"
    fi
}

# 部署配置文件
deploy_config() {
    log_info "Deploying Neovim configuration..."

    # Windows：若目标下存在误建的 %APPDATA% 目录则删除，避免 cp 报 same file
    if [[ "${PLATFORM}" == "windows" ]] && [[ -d "${NVIM_CONFIG_DIR}/%APPDATA%" ]]; then
        rm -rf "${NVIM_CONFIG_DIR}/%APPDATA%"
        log_info "Removed stray %APPDATA% directory from config"
    fi

    # 创建配置目录
    ensure_directory "${NVIM_CONFIG_DIR}"

    # 复制配置文件
    log_info "Copying configuration files..."
    if command -v rsync >/dev/null 2>&1; then
        # 使用 rsync（更高效，支持排除模式）；排除 %APPDATA% 等误建目录
        rsync -av --exclude='.git' --exclude='.gitignore' --exclude='test_dir' --exclude='%APPDATA%' \
            "${SCRIPT_DIR}/" "${NVIM_CONFIG_DIR}/" >/dev/null 2>&1 || {
            log_info "rsync failed, trying alternative method"
            deploy_config_cp
        }
    else
        deploy_config_cp
    fi

    log_success "Configuration files deployed to: ${NVIM_CONFIG_DIR}"
}

# 使用 cp 部署配置（rsync 不可用时的备选方案）
deploy_config_cp() {
    # 使用 find 和 cp 复制文件（排除不需要的目录及误建的 %APPDATA%）
    find "${SCRIPT_DIR}" -mindepth 1 -maxdepth 1 \
        ! -name '.git' ! -name '.gitignore' ! -name 'test_dir' ! -name '%APPDATA%' \
        -exec cp -r {} "${NVIM_CONFIG_DIR}/" \;
}

# 设置 Python 环境（使用 uv 管理）
setup_python_environment() {
    log_info "Setting up Python environment with uv..."

    # 检查是否使用系统级安装
    local use_system_venv="${USE_SYSTEM_NVIM_VENV:-0}"
    # 获取用户名：优先使用 INSTALL_USER，然后是 USER，最后使用 whoami 或 USERNAME
    local install_user="${INSTALL_USER:-${USER:-${USERNAME:-$(whoami 2>/dev/null || echo "user")}}}"

    # 确定虚拟环境路径
    if [[ "${use_system_venv}" == "1" ]]; then
        # 系统级安装：所有用户共享
        VENV_PATH="/usr/local/share/nvim/venv/nvim-python"
        log_info "Using system-wide Neovim Python environment (shared by all users)"
    else
        # 用户级安装：每个用户独立
        VENV_PATH="${HOME}/.config/nvim/venv/nvim-python"
        log_info "Using user-specific Neovim Python environment"
    fi

    log_info "Virtual environment path: ${VENV_PATH}"

    # 创建虚拟环境目录
    ensure_directory "$(dirname "${VENV_PATH}")"

    # 如果虚拟环境已存在，则更新包
    if [[ -d "${VENV_PATH}" ]]; then
        log_info "Virtual environment already exists, will update packages"
    else
        log_info "Creating virtual environment..."
        if [[ "${use_system_venv}" == "1" ]] && [[ "$EUID" -eq 0 ]]; then
            # 系统级：以 root 运行
            uv venv "${VENV_PATH}" || {
                log_error "Failed to create virtual environment"
                exit 1
            }
        else
            # 用户级：以当前用户运行
            uv venv "${VENV_PATH}" || {
                log_error "Failed to create virtual environment"
                exit 1
            }
        fi
        log_success "Virtual environment created"
    fi

    # Windows 上 uv 使用 Scripts/activate、Scripts/python.exe；macOS/Linux 使用 bin/
    if [[ "${PLATFORM}" == "windows" ]]; then
        if [[ -f "${VENV_PATH}/Scripts/activate" ]]; then
            VENV_ACTIVATE="${VENV_PATH}/Scripts/activate"
            if [[ -f "${VENV_PATH}/Scripts/python.exe" ]]; then
                VENV_PYTHON="${VENV_PATH}/Scripts/python.exe"
            else
                VENV_PYTHON="${VENV_PATH}/Scripts/python"
            fi
        else
            VENV_ACTIVATE="${VENV_PATH}/bin/activate"
            VENV_PYTHON="${VENV_PATH}/bin/python"
        fi
    else
        VENV_ACTIVATE="${VENV_PATH}/bin/activate"
        VENV_PYTHON="${VENV_PATH}/bin/python"
    fi

    # 确保 pip 已安装（使用 uv pip）
    log_info "Ensuring pip is installed..."
    if [[ -f "${VENV_ACTIVATE}" ]]; then
        # 检查 pip 是否可用
        local pip_available=0
        if source "${VENV_ACTIVATE}" 2>/dev/null; then
            if python -m pip --version >/dev/null 2>&1; then
                pip_available=1
            fi
        fi

        # 使用 uv pip 安装或升级 pip
        if [[ ${pip_available} -eq 0 ]]; then
            log_info "Installing pip via uv pip..."
        else
            log_info "Upgrading pip to latest version via uv pip..."
        fi

        if [[ "${use_system_venv}" == "1" ]] && [[ "$EUID" -eq 0 ]]; then
            # 系统级：以 root 运行
            (source "${VENV_ACTIVATE}" && uv pip install --upgrade pip >/dev/null 2>&1) || true
        else
            # 用户级：以当前用户运行
            (source "${VENV_ACTIVATE}" && uv pip install --upgrade pip >/dev/null 2>&1) || true
        fi

        # 验证 pip 是否可用
        if source "${VENV_ACTIVATE}" 2>/dev/null; then
            if python -m pip --version >/dev/null 2>&1; then
                local pip_version
                pip_version=$(python -m pip --version 2>&1 | head -n 1)
                log_success "pip is available: ${pip_version}"
            else
                log_info "pip may not be available, continuing with package installation"
            fi
        else
            log_info "Could not activate venv for pip verification, continuing"
        fi
    fi

    # 安装 Python 包
    local python_packages=(
        pynvim
        pyright
        ruff-lsp
        debugpy
        black
        isort
        flake8
        mypy
    )

    log_info "Installing Python packages: ${python_packages[*]}"
    log_info "This may take a few minutes..."

    # 检查已安装的包，只安装缺失的包
    local packages_to_install=()
    local installed_packages=""

    # 获取已安装的包列表
    if [[ -f "${VENV_ACTIVATE}" ]]; then
        installed_packages=$(source "${VENV_ACTIVATE}" && \
            uv pip list --format=freeze 2>/dev/null | cut -d'=' -f1 | tr '[:upper:]' '[:lower:]' || echo "")
    fi

    # 检查每个包是否需要安装
    for pkg in "${python_packages[@]}"; do
        local pkg_lower="${pkg,,}"  # 转换为小写
        if echo "${installed_packages}" | grep -q "^${pkg_lower}$"; then
            log_info "  ${pkg} already installed, skipping"
        else
            packages_to_install+=("${pkg}")
        fi
    done

    # 如果没有需要安装的包，直接返回
    if [[ ${#packages_to_install[@]} -eq 0 ]]; then
        log_success "All Python packages are already installed"
    else
        local total=${#packages_to_install[@]} idx=0
        for pkg in "${packages_to_install[@]}"; do
            idx=$((idx + 1))
            progress_sub "${idx}" "${total}" "pip: ${pkg}"
            local install_cmd="source '${VENV_ACTIVATE}' && uv pip install -U ${pkg}"
            if [[ "${use_system_venv}" == "1" ]] && [[ "$EUID" -eq 0 ]]; then
                timeout 120 bash -c "${install_cmd}" >/dev/null 2>&1 || log_info "  ${pkg} install skipped or failed"
            else
                timeout 120 bash -c "${install_cmd}" >/dev/null 2>&1 || log_info "  ${pkg} install skipped or failed"
            fi
        done
        log_success "Python packages installation completed"
    fi
}

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

    # 检查是否已安装 Node.js
    local node_installed=0
    if command -v node >/dev/null 2>&1; then
        local node_version
        node_version=$(node --version 2>/dev/null || echo "")
        if [[ -n "${node_version}" ]]; then
            node_installed=1
            log_success "Node.js already installed: ${node_version}"
        fi
    fi

    # 如果未安装，使用 fnm 安装 LTS 版本
    if [[ ${node_installed} -eq 0 ]]; then
        log_info "Installing Node.js LTS version using fnm..."
        # 安装 LTS 版本（使用 lts/* 表示最新的 LTS 版本）
        if fnm install lts/* 2>&1; then
            # 安装成功后，使用 lts/* 激活
            fnm use lts/* || {
                # 如果 lts/* 不工作，尝试获取已安装的 LTS 版本
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
            log_success "Node.js LTS installed and activated"
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
        }

        if _npm list -g neovim >/dev/null 2>&1; then
            log_success "neovim npm package already installed"
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
        npm_global_root="$(_npm root -g 2>/dev/null | tr -d '\r\n')"
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

        # 安装 tree-sitter CLI（建议 >= 0.26.1）和 pnpm（用于健康检查）
        if ! command -v tree-sitter >/dev/null 2>&1; then
            log_info "Installing tree-sitter CLI (recommended >= 0.26.1)..."
            if _npm install -g tree-sitter-cli >/dev/null 2>&1; then
                log_success "tree-sitter CLI installed"
            else
                log_info "tree-sitter CLI installation failed, continuing"
            fi
        else
            log_success "tree-sitter CLI already installed"
        fi
        _npm_cleanup_stray

        if ! command -v pnpm >/dev/null 2>&1; then
            log_info "Installing pnpm..."
            if _npm install -g pnpm >/dev/null 2>&1; then
                log_success "pnpm installed"
            else
                log_info "pnpm installation failed, continuing"
            fi
        else
            log_success "pnpm already installed"
        fi
        _npm_cleanup_stray
        if [[ "${PLATFORM}" == "windows" ]] && [[ -d "${SCRIPT_DIR}/%APPDATA%" ]]; then
            rm -rf "${SCRIPT_DIR}/%APPDATA%"
            log_info "Removed stray %APPDATA% directory created by npm"
        fi
    else
        log_info "npm not found, skipping npm package installation"
    fi

    # 安装 Ruby neovim gem（如果 Ruby 可用）
    if command -v ruby >/dev/null 2>&1; then
        if gem list neovim 2>/dev/null | grep -q neovim; then
            log_success "neovim Ruby gem already installed"
        else
            log_info "Installing neovim Ruby gem..."
            if gem install neovim >/dev/null 2>&1; then
                log_success "neovim Ruby gem installed"
            else
                record_failed "neovim Ruby gem"
                log_info "neovim Ruby gem installation failed, continuing"
            fi
        fi
    else
        log_info "Ruby not found, skipping neovim gem installation"
    fi
}

# 检测 opencode 可执行路径（按 PLATFORM 分支，供 nvim opencode.nvim 使用）
# 设置全局 OPENCODE_CMD，未检测到则为空
detect_opencode_path() {
    OPENCODE_CMD=""
    if [[ "${PLATFORM}" == "linux" ]] || [[ "${PLATFORM}" == "macos" ]]; then
        if command -v opencode >/dev/null 2>&1; then
            OPENCODE_CMD="$(command -v opencode)"
            log_success "opencode found: ${OPENCODE_CMD}"
        else
            record_failed "opencode"
            log_info "opencode not found in PATH (optional for AI features)"
        fi
    elif [[ "${PLATFORM}" == "windows" ]]; then
        if command -v opencode >/dev/null 2>&1; then
            OPENCODE_CMD="$(command -v opencode)"
            log_success "opencode found: ${OPENCODE_CMD}"
        else
            record_failed "opencode"
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

    log_info ""
    log_info "Next steps:"
    log_info "1. Start Neovim: nvim"
    log_info "2. If using lazy.nvim, plugins will be automatically installed"
    log_info "3. If using vim-plug, run: :PlugInstall"
    log_info ""
    log_info "To update configuration:"
    log_info "  cd ${NVIM_CONFIG_DIR}"
    log_info "  git pull"
    log_info "  Then run this install script again"
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

    # Windows：脚本一开始就清理可能存在的 %APPDATA% 并导出已展开的 APPDATA，避免 step 1～6 中任何子进程（如 fnm）在 cwd 下创建该目录
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
    check_submodule

    normalize_windows_home

    progress_step 2 "${TOTAL_MAIN_STEPS}" "Determining config directory..."
    determine_config_dir

    progress_step 3 "${TOTAL_MAIN_STEPS}" "Checking Windows config..."
    check_windows_config

    progress_step 4 "${TOTAL_MAIN_STEPS}" "Checking prerequisites..."
    check_prerequisites

    progress_step 5 "${TOTAL_MAIN_STEPS}" "Installing language tools (Go, Ruby, Composer, Rust, C/C++)..."
    install_language_tools

    progress_step 6 "${TOTAL_MAIN_STEPS}" "Checking clipboard tool..."
    install_clipboard_tool

    progress_step 7 "${TOTAL_MAIN_STEPS}" "Backing up existing config..."
    backup_existing_config

    progress_step 8 "${TOTAL_MAIN_STEPS}" "Deploying config files..."
    deploy_config

    progress_step 9 "${TOTAL_MAIN_STEPS}" "Setting up Python environment (uv)..."
    setup_python_environment

    progress_step 10 "${TOTAL_MAIN_STEPS}" "Setting up Node.js environment (fnm)..."
    setup_nodejs_environment

    progress_step 11 "${TOTAL_MAIN_STEPS}" "Configuring Neovim paths..."
    configure_neovim_paths

    progress_step 12 "${TOTAL_MAIN_STEPS}" "Checking plugin manager..."
    check_plugin_manager

    progress_step 13 "${TOTAL_MAIN_STEPS}" "Verifying installation..."
    verify_installation

    progress_step 14 "${TOTAL_MAIN_STEPS}" "TreeSitter parsers..."
    install_treesitter_parsers

    progress_step 15 "${TOTAL_MAIN_STEPS}" "Printing summary..."
    print_summary

    end_script
}

# 执行主函数
main "$@"
