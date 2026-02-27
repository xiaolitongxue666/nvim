#!/usr/bin/env bash

# Neovim 配置安装脚本
# 支持 macOS、Linux、Windows、WSL
# 独立仓库，使用 uv 管理 Python 环境，使用 fnm 管理 Node.js 环境

# 启用严格模式：遇到错误立即退出，未定义变量报错，管道中任一命令失败则整个管道失败
set -euo pipefail
# 设置默认文件权限掩码
umask 022

# 本仓库根目录（安装脚本所在目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 通用脚本库路径（本仓库 scripts/ 下）
COMMON_LIB="${SCRIPT_DIR}/scripts/common.sh"

# 检查通用脚本库是否存在
if [[ ! -f "${COMMON_LIB}" ]]; then
    echo "[ERROR] Common script library not found: ${COMMON_LIB}" >&2
    exit 1
fi

# 引入通用日志/错误处理函数
# shellcheck disable=SC1090
source "${COMMON_LIB}"

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
NODE_PATH=""
BACKUP_DIR=""

# 错误处理：捕获 ERR 信号并记录错误信息
trap 'log_error "Error detected at line ${LINENO}, exiting script"; exit 1' ERR

# 清理函数：在脚本退出时清理临时文件
cleanup() {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        log_warning "Script exited with error code: ${exit_code}"
    fi
    trap - EXIT ERR
}

trap cleanup EXIT

# 带超时运行命令（macOS 默认无 timeout，则直接执行）
run_with_timeout() {
    local seconds="$1"
    shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "${seconds}" "$@"
    else
        "$@"
    fi
}

# 检查配置完整性（init.lua 或 lua/ 至少存在其一）
check_config_integrity() {
    if [[ ! -f "${SCRIPT_DIR}/init.lua" ]] && [[ ! -d "${SCRIPT_DIR}/lua" ]]; then
        log_error "Configuration incomplete: init.lua or lua/ not found"
        log_info "Please run this script from the root of the nvim config repository."
        exit 1
    fi
    log_success "Configuration integrity check passed"
}

# 检查前置依赖（uv, fnm, lua）
check_prerequisites() {
    log_info "Checking prerequisites..."

    # 检查 uv
    if ! command -v uv >/dev/null 2>&1; then
        error_exit "uv is not installed. See README for install commands (e.g. macOS: brew install uv; Linux: see https://github.com/astral-sh/uv)"
    fi
    log_success "uv found: $(uv --version | head -n 1)"

    # 检查 fnm
    if ! command -v fnm >/dev/null 2>&1; then
        error_exit "fnm is not installed. See README for install commands (e.g. macOS: brew install fnm; Linux: see https://github.com/Schniz/fnm)"
    fi
    log_success "fnm found: $(fnm --version)"

    # 检查 Lua（通过 lua 命令或 pacman）
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
        log_warning "Lua is not installed"
        install_lua
    fi

    log_success "All prerequisites checked"
}

# 安装语言工具（Go, Ruby, Composer）
install_language_tools() {
    log_info "Installing language tools for mason.nvim..."

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
    if ! command -v composer >/dev/null 2>&1; then
        tools_to_install+=("composer")
    else
        log_success "Composer already installed: $(composer --version 2>&1 | head -n 1)"
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
                esac
            done

            if [[ ${#pacman_packages[@]} -gt 0 ]]; then
                log_info "Installing packages via pacman (requires sudo): ${pacman_packages[*]}"
                if sudo pacman -S --noconfirm "${pacman_packages[@]}" 2>&1; then
                    log_success "Language tools installed successfully"
                else
                    log_warning "Failed to install some language tools via pacman"
                    log_info "You can install them manually:"
                    log_info "  sudo pacman -S ${pacman_packages[*]}"
                fi
            fi
        elif command -v apt-get >/dev/null 2>&1; then
            # Debian/Ubuntu
            local apt_packages=()
            for tool in "${tools_to_install[@]}"; do
                case "${tool}" in
                    "go")
                        apt_packages+=("golang-go")
                        ;;
                    "ruby")
                        apt_packages+=("ruby")
                        ;;
                    "composer")
                        apt_packages+=("composer")
                        ;;
                esac
            done

            if [[ ${#apt_packages[@]} -gt 0 ]]; then
                log_info "Installing packages via apt-get (requires sudo): ${apt_packages[*]}"
                if sudo apt-get update >/dev/null 2>&1 && \
                   sudo apt-get install -y "${apt_packages[@]}" 2>&1; then
                    log_success "Language tools installed successfully"
                else
                    log_warning "Failed to install some language tools via apt-get"
                    log_info "You can install them manually:"
                    log_info "  sudo apt-get update && sudo apt-get install -y ${apt_packages[*]}"
                fi
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
                esac
            done

            if [[ ${#yum_packages[@]} -gt 0 ]]; then
                log_info "Installing packages via yum (requires sudo): ${yum_packages[*]}"
                if sudo yum install -y "${yum_packages[@]}" 2>&1; then
                    log_success "Language tools installed successfully"
                else
                    log_warning "Failed to install some language tools via yum"
                    log_info "You can install them manually:"
                    log_info "  sudo yum install -y ${yum_packages[*]}"
                fi
            fi
        else
            log_warning "No supported package manager found for Linux"
            log_info "Please install language tools manually"
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
                esac
            done

            if [[ ${#brew_packages[@]} -gt 0 ]]; then
                log_info "Installing packages via Homebrew: ${brew_packages[*]}"
                if brew install "${brew_packages[@]}" 2>&1; then
                    log_success "Language tools installed successfully"
                else
                    log_warning "Failed to install some language tools via Homebrew"
                    log_info "You can install them manually:"
                    log_info "  brew install ${brew_packages[*]}"
                fi
            fi
        else
            log_warning "Homebrew not found"
            log_info "Please install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
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
                        log_warning "Go installation failed, please install manually: winget install GoLang.Go"
                    fi
                fi
            else
                log_warning "winget not found, please install Go manually: https://golang.org/dl/"
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
                    log_warning "Composer installation verification failed"
                fi
            else
                log_warning "Composer download failed, please install manually: https://getcomposer.org/download/"
            fi
        fi

        # Ruby 在 Windows 上通常已安装（通过 RubyInstaller），只需检查
        if [[ " ${tools_to_install[*]} " =~ " ruby " ]]; then
            log_info "Checking Ruby installation..."
            if ! command -v ruby >/dev/null 2>&1; then
                log_warning "Ruby not found, please install manually: https://rubyinstaller.org/ or winget install RubyInstallerTeam.Ruby"
            fi
        fi
    fi
}

# 安装 Lua（如果需要）
install_lua() {
    log_info "Installing Lua..."

    if [[ "${PLATFORM}" == "linux" ]] && command -v pacman >/dev/null 2>&1; then
        log_info "Installing Lua via pacman (requires sudo)"
        if sudo pacman -S --noconfirm lua >/dev/null 2>&1; then
            log_success "Lua installed successfully"
        else
            log_warning "Failed to install Lua via pacman, please install manually"
            log_info "Run: sudo pacman -S lua"
        fi
    elif [[ "${PLATFORM}" == "macos" ]] && command -v brew >/dev/null 2>&1; then
        log_info "Installing Lua via Homebrew"
        if brew install lua >/dev/null 2>&1; then
            log_success "Lua installed successfully"
        else
            log_warning "Failed to install Lua via Homebrew, please install manually"
            log_info "Run: brew install lua"
        fi
    else
        log_warning "Cannot automatically install Lua on this platform"
        log_info "Please install Lua manually for your system"
        log_info "Arch Linux: sudo pacman -S lua"
        log_info "macOS: brew install lua"
        log_info "Windows: Download from https://luabinaries.sourceforge.net/"
    fi
}

# 确定配置目录
determine_config_dir() {
    if [[ "${PLATFORM}" == "windows" ]] && [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
        # Windows 使用 XDG_CONFIG_HOME
        NVIM_CONFIG_DIR="${XDG_CONFIG_HOME}/nvim"
        # 转换路径格式（如果包含反斜杠）
        NVIM_CONFIG_DIR="${NVIM_CONFIG_DIR//\\//}"
    else
        # macOS/Linux 使用标准路径
        NVIM_CONFIG_DIR="${HOME}/.config/nvim"
    fi

    log_info "Neovim config directory: ${NVIM_CONFIG_DIR}"
}

# 检查 Windows XDG_CONFIG_HOME
check_windows_config() {
    if [[ "${PLATFORM}" == "windows" ]] && [[ -z "${XDG_CONFIG_HOME:-}" ]]; then
        log_warning "XDG_CONFIG_HOME environment variable is not set on Windows"
        log_info "To use Neovim on Windows, you need to configure XDG_CONFIG_HOME"
        log_info "Configuration steps:"
        log_info "1. Open System Properties -> Advanced System Settings -> Environment Variables"
        log_info "2. Add user variable:"
        log_info "   - Variable name: XDG_CONFIG_HOME"
        log_info "   - Variable value: C:\\Users\\<username>\\.config\\"
        log_info "     Example: C:\\Users\\Administrator\\.config\\"
        log_info "3. Restart terminal"
        log_warning "Config files may not be installed to the expected location"
    fi
}

# 备份现有配置
backup_existing_config() {
    if [[ -d "${NVIM_CONFIG_DIR}" ]] && [[ -n "$(ls -A "${NVIM_CONFIG_DIR}" 2>/dev/null)" ]]; then
        BACKUP_DIR="${NVIM_CONFIG_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Existing configuration detected, creating backup..."

        if cp -r "${NVIM_CONFIG_DIR}" "${BACKUP_DIR}" 2>/dev/null; then
            log_success "Configuration backed up to: ${BACKUP_DIR}"
        else
            log_warning "Backup failed, but continuing with installation"
            BACKUP_DIR=""
        fi
    else
        log_info "No existing configuration found, skipping backup"
    fi
}

# 部署配置文件
deploy_config() {
    log_info "Deploying Neovim configuration..."

    # 创建配置目录
    ensure_directory "${NVIM_CONFIG_DIR}"

    # 复制配置文件
    log_info "Copying configuration files..."
    if command -v rsync >/dev/null 2>&1; then
        # 使用 rsync（更高效，支持排除模式）
        rsync -av --exclude='.git' --exclude='.gitignore' --exclude='test_dir' \
            "${SCRIPT_DIR}/" "${NVIM_CONFIG_DIR}/" >/dev/null 2>&1 || {
            log_warning "rsync failed, trying alternative method"
            deploy_config_cp
        }
    else
        deploy_config_cp
    fi

    log_success "Configuration files deployed to: ${NVIM_CONFIG_DIR}"
}

# 使用 cp 部署配置（rsync 不可用时的备选方案）
deploy_config_cp() {
    # 使用 find 和 cp 复制文件（排除不需要的目录）
    find "${SCRIPT_DIR}" -mindepth 1 -maxdepth 1 \
        ! -name '.git' ! -name '.gitignore' ! -name 'test_dir' \
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

    # 确保 pip 已安装（使用 uv pip）
    log_info "Ensuring pip is installed..."
    if [[ -f "${VENV_PATH}/bin/activate" ]]; then
        # 检查 pip 是否可用
        local pip_available=0
        if source "${VENV_PATH}/bin/activate" 2>/dev/null; then
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
            (source "${VENV_PATH}/bin/activate" && uv pip install --upgrade pip >/dev/null 2>&1) || {
                log_warning "Failed to install/upgrade pip via uv pip, but continuing"
            }
        else
            # 用户级：以当前用户运行
            (source "${VENV_PATH}/bin/activate" && uv pip install --upgrade pip >/dev/null 2>&1) || {
                log_warning "Failed to install/upgrade pip via uv pip, but continuing"
            }
        fi

        # 验证 pip 是否可用
        if source "${VENV_PATH}/bin/activate" 2>/dev/null; then
            if python -m pip --version >/dev/null 2>&1; then
                local pip_version
                pip_version=$(python -m pip --version 2>&1 | head -n 1)
                log_success "pip is available: ${pip_version}"
            else
                log_warning "pip may not be available, but continuing with package installation"
            fi
        else
            log_warning "Failed to activate virtual environment for pip verification"
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
    if [[ -f "${VENV_PATH}/bin/activate" ]]; then
        installed_packages=$(source "${VENV_PATH}/bin/activate" && \
            uv pip list --format=freeze 2>/dev/null | cut -d'=' -f1 | tr '[:upper:]' '[:lower:]' || echo "")
    fi

    # 检查每个包是否需要安装（使用 tr 兼容 macOS 默认 bash 3.x）
    for pkg in "${python_packages[@]}"; do
        local pkg_lower
        pkg_lower=$(echo "${pkg}" | tr '[:upper:]' '[:lower:]')
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
        log_info "Installing ${#packages_to_install[@]} packages: ${packages_to_install[*]}"

        # 使用 uv pip 安装包
        local install_cmd="source '${VENV_PATH}/bin/activate' && uv pip install -U ${packages_to_install[*]}"

        if [[ "${use_system_venv}" == "1" ]] && [[ "$EUID" -eq 0 ]]; then
            # 系统级：以 root 运行
            run_with_timeout 600 bash -c "${install_cmd}" || {
                log_warning "Some packages may have failed to install, but continuing"
            }
        else
            # 用户级：以当前用户运行
            run_with_timeout 600 bash -c "${install_cmd}" || {
                log_warning "Some packages may have failed to install, but continuing"
            }
        fi

        log_success "Python packages installation completed"
    fi
}

# 设置 Node.js 环境（使用 fnm 管理）
setup_nodejs_environment() {
    log_info "Setting up Node.js environment with fnm..."

    # 初始化 fnm 环境
    # 尝试多种方式初始化 fnm 环境
    if [[ -f "${HOME}/.local/share/fnm/fnm" ]]; then
        # fnm 安装在用户目录
        eval "$("${HOME}/.local/share/fnm/fnm" env --use-on-cd)" || {
            log_warning "Failed to initialize fnm from user directory, trying system path"
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

    # 获取 Node.js 路径
    NODE_PATH="$(command -v node 2>/dev/null || echo "")"
    if [[ -z "${NODE_PATH}" ]]; then
        # 尝试从 fnm 目录查找
        local fnm_node_path
        fnm_node_path=$(fnm list 2>/dev/null | grep -E "lts|default" | head -n 1 | awk '{print $2}' || echo "")
        if [[ -n "${fnm_node_path}" ]]; then
            # 构建完整路径
            local fnm_dir="${HOME}/.local/share/fnm"
            if [[ -d "${fnm_dir}/aliases/${fnm_node_path}" ]]; then
                NODE_PATH="${fnm_dir}/aliases/${fnm_node_path}/bin/node"
            fi
        fi
    fi

    if [[ -n "${NODE_PATH}" ]] && [[ -f "${NODE_PATH}" ]]; then
        log_info "Node.js path: ${NODE_PATH}"
    else
        log_warning "Could not determine Node.js path, but continuing"
        NODE_PATH=""
    fi

    # 检查 neovim npm 包是否已安装
    if command -v npm >/dev/null 2>&1; then
        # 确保 Windows 环境变量正确传递（Git Bash 需要）
        if [[ "${PLATFORM}" == "windows" ]] && [[ -z "${APPDATA:-}" ]]; then
            # 尝试从 Windows 环境获取 APPDATA
            if command -v cmd.exe >/dev/null 2>&1; then
                export APPDATA="$(cmd.exe //c "echo %APPDATA%" 2>/dev/null | tr -d '\r\n' || echo "")"
            fi
        fi

        if npm list -g neovim >/dev/null 2>&1; then
            log_success "neovim npm package already installed"
        else
            log_info "Installing neovim npm package..."
            if npm install -g neovim >/dev/null 2>&1; then
                log_success "neovim npm package installed"
            else
                log_warning "Failed to install neovim npm package, but continuing"
                log_info "You can install it manually later: npm install -g neovim"
            fi
        fi

        # 安装 tree-sitter CLI 和 pnpm（用于健康检查）
        if ! command -v tree-sitter >/dev/null 2>&1; then
            log_info "Installing tree-sitter CLI..."
            if npm install -g tree-sitter-cli >/dev/null 2>&1; then
                log_success "tree-sitter CLI installed"
            else
                log_warning "tree-sitter CLI installation failed, but continuing"
            fi
        else
            log_success "tree-sitter CLI already installed"
        fi

        if ! command -v pnpm >/dev/null 2>&1; then
            log_info "Installing pnpm..."
            if npm install -g pnpm >/dev/null 2>&1; then
                log_success "pnpm installed"
            else
                log_warning "pnpm installation failed, but continuing"
            fi
        else
            log_success "pnpm already installed"
        fi
    else
        log_warning "npm not found, skipping npm package installation"
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
                log_warning "neovim Ruby gem installation failed, but continuing"
            fi
        fi
    else
        log_info "Ruby not found, skipping neovim gem installation"
    fi
}

# 配置 Neovim 路径（Python 和 Node.js）
configure_neovim_paths() {
    log_info "Configuring Neovim paths for Python and Node.js..."

    local config_file="${NVIM_CONFIG_DIR}/init.lua"
    if [[ ! -f "${config_file}" ]]; then
        log_warning "init.lua not found, skipping path configuration"
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

    # 如果都配置了，直接返回
    if [[ ${python_configured} -eq 1 ]] && [[ ${node_configured} -eq 1 ]]; then
        log_success "All paths already configured"
        return 0
    fi

    # 创建配置片段
    local config_snippet=""

    if [[ ${python_configured} -eq 0 ]] && [[ -n "${VENV_PATH:-}" ]] && [[ -f "${VENV_PATH}/bin/python" ]]; then
        config_snippet="${config_snippet}
-- Python interpreter path (auto-configured by install.sh)
vim.g.python3_host_prog = \"${VENV_PATH}/bin/python\"
-- Add virtual environment site-packages to pythonpath
local venv_path = \"${VENV_PATH}\"
vim.opt.pp:prepend(venv_path .. \"/lib/python*/site-packages\")
"
    fi

    if [[ ${node_configured} -eq 0 ]] && [[ -n "${NODE_PATH:-}" ]]; then
        config_snippet="${config_snippet}
-- Node.js interpreter path (auto-configured by install.sh)
vim.g.node_host_prog = \"${NODE_PATH}\"
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
        log_warning "lazy.nvim not found, checking for vim-plug..."
        local vim_plug_dir="${HOME}/.local/share/nvim/site/autoload"
        if [[ ! -f "${vim_plug_dir}/plug.vim" ]]; then
            log_info "Installing vim-plug..."
            ensure_directory "${vim_plug_dir}"
            if curl -fLo "${vim_plug_dir}/plug.vim" --create-dirs \
                https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim 2>/dev/null; then
                log_success "vim-plug installed"
            else
                log_warning "Failed to install vim-plug"
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
    if [[ -n "${VENV_PATH:-}" ]] && [[ -f "${VENV_PATH}/bin/python" ]]; then
        log_success "Python environment found: ${VENV_PATH}"
    else
        log_warning "Python environment not configured"
    fi

    # 验证 Node.js 环境
    if [[ -n "${NODE_PATH:-}" ]] && command -v node >/dev/null 2>&1; then
        log_success "Node.js environment found: ${NODE_PATH}"
    else
        log_warning "Node.js environment not configured"
    fi

    # 验证 lazy.nvim
    if [[ -f "${NVIM_CONFIG_DIR}/lua/config/lazy.lua" ]]; then
        log_success "lazy.nvim configuration found"
    else
        log_warning "lazy.nvim configuration not found"
    fi

    if [[ ${errors} -eq 0 ]]; then
        log_success "Installation verification completed"
    else
        log_warning "Installation verification found ${errors} error(s)"
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
    log_warning "No clipboard tool found. Clipboard registers (\"+ and \"*) will not work."
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
                log_warning "Failed to install xclip via apt-get"
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
                log_warning "Failed to install xclip via yum"
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
                log_warning "Failed to install xclip via pacman"
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
                log_warning "Failed to install xclip via dnf"
                log_info "You can manually install it: sudo dnf install -y xclip"
            fi
        else
            log_warning "No supported package manager found for Linux"
            log_info "Please install xclip or xsel manually:"
            log_info "  Debian/Ubuntu: sudo apt-get install -y xclip"
            log_info "  RHEL/CentOS:   sudo yum install -y xclip"
            log_info "  Arch Linux:    sudo pacman -S xclip"
            log_info "  Fedora:        sudo dnf install -y xclip"
        fi
    elif [[ "${PLATFORM}" == "macos" ]]; then
        # macOS: pbcopy/pbpaste 应该总是可用，如果不可用可能是系统问题
        log_error "pbcopy/pbpaste not found on macOS. This is unusual."
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
        log_warning "Clipboard tool installation failed or skipped"
        log_info "Clipboard registers (\"+ and \"*) will not work in Neovim"
        log_info "You can install it manually later. See: :help clipboard"
    fi
}

# 安装 TreeSitter parsers
install_treesitter_parsers() {
    log_info "Installing TreeSitter parsers..."

    # 检查 Neovim 是否可用
    if ! command -v nvim >/dev/null 2>&1; then
        log_warning "Neovim not found, skipping TreeSitter parser installation"
        log_info "TreeSitter parsers will be installed automatically on first Neovim startup"
        return 0
    fi

    # 检查配置文件是否存在
    if [[ ! -f "${NVIM_CONFIG_DIR}/init.lua" ]]; then
        log_warning "Neovim configuration not found, skipping TreeSitter parser installation"
        return 0
    fi

    log_info "Installing TreeSitter parsers: bash, regex"
    log_info "This may take a few minutes..."

    # 使用 nvim --headless 执行 TSInstall 和 TSUpdate
    # 使用 -c 参数直接执行命令，等待插件加载
    log_info "You Shoule Maunal Run TreeSitter installation commands...(TSUpdate)"

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
    log_info "  cd <this repo root>"
    log_info "  git pull"
    log_info "  ./install.sh"
    log_info ""
}

# 主函数
main() {
    start_script "Neovim Configuration Installation"

    # 检查配置完整性
    check_config_integrity

    # 确定配置目录
    determine_config_dir

    # 检查 Windows 配置
    check_windows_config

    # 检查前置依赖
    check_prerequisites

    # 安装语言工具（Go, Ruby, Composer）
    install_language_tools

    # 检查并安装 clipboard 工具
    install_clipboard_tool

    # 备份现有配置
    backup_existing_config

    # 部署配置文件
    deploy_config

    # 设置 Python 环境（使用 uv）
    setup_python_environment

    # 设置 Node.js 环境（使用 fnm）
    setup_nodejs_environment

    # 配置 Neovim 路径
    configure_neovim_paths

    # 检查插件管理器
    check_plugin_manager

    # 验证安装
    verify_installation

    # 安装 TreeSitter parsers
    install_treesitter_parsers

    # 打印摘要
    print_summary

    end_script
}

# 执行主函数
main "$@"
