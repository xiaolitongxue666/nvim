#!/bin/bash

# Neovim 配置安装脚本
# 支持 macOS、Linux、Windows 系统
# 使用 Git Submodule 管理配置

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

echo "=========================================="
echo "Neovim 配置安装脚本"
echo "=========================================="
echo "检测到操作系统: $OS"
echo ""

# 检测操作系统
if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="macos"
elif [[ "$OS" == "Linux" ]]; then
    PLATFORM="linux"
elif [[ "$OS" == MINGW* ]] || [[ "$OS" == MSYS* ]] || [[ "$OS" == CYGWIN* ]]; then
    PLATFORM="windows"
else
    echo "错误: 不支持的操作系统: $OS"
    exit 1
fi

# 检查 submodule 是否存在
if [ ! -f "$SCRIPT_DIR/init.lua" ] && [ ! -d "$SCRIPT_DIR/lua" ]; then
    echo "=========================================="
    echo "警告: Neovim Submodule 未初始化"
    echo "=========================================="
    echo "请先初始化 Git Submodule："
    echo ""
    echo "  cd script_tool_and_config"
    echo "  git submodule update --init --recursive"
    echo ""
    echo "或者："
    echo "  git submodule update --init dotfiles/nvim"
    echo ""
    exit 1
fi

# Windows 特殊处理
if [[ "$PLATFORM" == "windows" ]]; then
    echo "=========================================="
    echo "Windows 配置检查"
    echo "=========================================="

    # 检查 XDG_CONFIG_HOME 环境变量
    if [ -z "$XDG_CONFIG_HOME" ]; then
        echo "警告: 未设置 XDG_CONFIG_HOME 环境变量"
        echo ""
        echo "在 Windows 上使用 Neovim 时，需要配置 XDG_CONFIG_HOME 环境变量"
        echo "以便 Neovim 能够正确找到配置文件位置"
        echo ""
        echo "配置步骤："
        echo "1. 打开系统属性 -> 高级系统设置 -> 环境变量"
        echo "2. 添加用户变量："
        echo "   - 变量名：XDG_CONFIG_HOME"
        echo "   - 变量值：C:\\Users\\<用户名>\\.config\\"
        echo "     例如：C:\\Users\\Administrator\\.config\\"
        echo "3. 重新启动终端"
        echo ""
        echo "详细说明请参考 README.md"
        echo ""
        read -p "是否已配置 XDG_CONFIG_HOME？(y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "警告: 配置文件可能无法正确安装到预期位置"
        fi
    else
        echo "✅ XDG_CONFIG_HOME 已设置: $XDG_CONFIG_HOME"
    fi
    echo ""
fi

# 确定配置目录
if [[ "$PLATFORM" == "windows" ]] && [ -n "$XDG_CONFIG_HOME" ]; then
    # Windows 使用 XDG_CONFIG_HOME
    NVIM_CONFIG_DIR="$XDG_CONFIG_HOME/nvim"
    # 转换路径格式（如果包含反斜杠）
    NVIM_CONFIG_DIR="${NVIM_CONFIG_DIR//\\//}"
else
    # macOS/Linux 使用标准路径
    NVIM_CONFIG_DIR="$HOME/.config/nvim"
fi

# 同步配置文件
echo "=========================================="
echo "同步配置文件"
echo "=========================================="

# 创建配置目录
mkdir -p "$NVIM_CONFIG_DIR"

# 备份现有配置（如果存在）
if [ -d "$NVIM_CONFIG_DIR" ] && [ "$(ls -A $NVIM_CONFIG_DIR 2>/dev/null)" ]; then
    BACKUP_DIR="$NVIM_CONFIG_DIR.backup.$(date +%Y%m%d_%H%M%S)"
    echo "检测到现有配置，正在备份..."
    cp -r "$NVIM_CONFIG_DIR" "$BACKUP_DIR" 2>/dev/null || {
        echo "⚠️  备份失败，但将继续安装"
    }
    if [ -d "$BACKUP_DIR" ]; then
        echo "✅ 已备份现有配置到: $BACKUP_DIR"
    fi
fi

# 复制配置文件
echo "正在复制配置文件..."
if [ -d "$SCRIPT_DIR" ]; then
    # 排除 .git 目录和其他不需要的文件
    rsync -av --exclude='.git' --exclude='.gitignore' --exclude='test_dir' "$SCRIPT_DIR/" "$NVIM_CONFIG_DIR/" 2>/dev/null || {
        # 如果 rsync 不可用，使用 cp
        find "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 ! -name '.git' ! -name '.gitignore' ! -name 'test_dir' -exec cp -r {} "$NVIM_CONFIG_DIR/" \;
    }
    echo "✅ 配置文件已复制到: $NVIM_CONFIG_DIR"
else
    echo "❌ 错误: 未找到配置文件目录: $SCRIPT_DIR"
    exit 1
fi

# 安装 vim-plug（如果需要）
echo ""
echo "=========================================="
echo "检查插件管理器"
echo "=========================================="

# 检查是否使用 lazy.nvim（通过检查 lua/config/lazy.lua）
if [ -f "$NVIM_CONFIG_DIR/lua/config/lazy.lua" ]; then
    echo "✅ 检测到 lazy.nvim 插件管理器"
    echo "首次启动 Neovim 时会自动安装插件"
else
    echo "正在安装 vim-plug..."
    VIM_PLUG_DIR="$HOME/.local/share/nvim/site/autoload"
    mkdir -p "$VIM_PLUG_DIR"
    curl -fLo "$VIM_PLUG_DIR/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    echo "✅ vim-plug 已安装"
fi

# Linux 系统：安装 Python 环境（如果 uv 可用且环境变量设置）
if [[ "$PLATFORM" == "linux" ]] && command -v uv >/dev/null 2>&1; then
    echo ""
    echo "=========================================="
    echo "配置 Neovim Python 环境"
    echo "=========================================="

    # 检查是否使用系统级安装
    use_system_venv="${USE_SYSTEM_NVIM_VENV:-0}"
    install_user="${INSTALL_USER:-$USER}"

    # 确定虚拟环境路径
    venv_dir=""
    venv_path=""

    if [[ "${use_system_venv}" == "1" ]]; then
        # 系统级安装：所有用户共享
        venv_dir="/usr/local/share/nvim/venv"
        venv_path="${venv_dir}/nvim-python"
        echo "使用系统级 Neovim Python 环境（所有用户共享）"
    else
        # 用户级安装：每个用户独立
        venv_dir="${HOME}/.config/nvim/venv"
        venv_path="${venv_dir}/nvim-python"
        echo "使用用户级 Neovim Python 环境"
    fi

    echo "虚拟环境路径: ${venv_path}"

    # 创建虚拟环境目录
    mkdir -p "${venv_dir}"

    # 如果虚拟环境已存在，则更新包
    if [[ -d "${venv_path}" ]]; then
        echo "虚拟环境已存在，将更新包"
    else
        echo "创建虚拟环境..."
        if [[ "${use_system_venv}" == "1" ]] && [[ "$EUID" -eq 0 ]]; then
            # 系统级：以 root 运行
            uv venv "${venv_path}" || {
                echo "⚠️  创建虚拟环境失败"
                exit 1
            }
        else
            # 用户级：以当前用户运行
            uv venv "${venv_path}" || {
                echo "⚠️  创建虚拟环境失败"
                exit 1
            }
        fi
        echo "✅ 虚拟环境已创建"
    fi

    # 安装 Python 包
    python_packages=(
        pynvim
        pyright
        ruff-lsp
        debugpy
        black
        isort
        flake8
        mypy
    )

    echo "安装 Python 包: ${python_packages[*]}"
    echo "这可能需要几分钟..."

    # 检查已安装的包，只安装缺失的包
    packages_to_install=()
    installed_packages=""

    # 获取已安装的包列表
    if [[ "${use_system_venv}" == "1" ]] && [[ "$EUID" -eq 0 ]]; then
        installed_packages=$(source "${venv_path}/bin/activate" && uv pip list --format=freeze 2>/dev/null | cut -d'=' -f1 | tr '[:upper:]' '[:lower:]' || echo "")
    else
        installed_packages=$(source "${venv_path}/bin/activate" && uv pip list --format=freeze 2>/dev/null | cut -d'=' -f1 | tr '[:upper:]' '[:lower:]' || echo "")
    fi

    # 检查每个包是否需要安装
    for pkg in "${python_packages[@]}"; do
        pkg_lower="${pkg,,}"  # 转换为小写
        if echo "${installed_packages}" | grep -q "^${pkg_lower}$"; then
            echo "  ✓ ${pkg} 已安装，跳过"
        else
            packages_to_install+=("${pkg}")
        fi
    done

    # 如果没有需要安装的包，直接返回
    if [[ ${#packages_to_install[@]} -eq 0 ]]; then
        echo "✅ 所有包已安装"
    else
        echo "安装 ${#packages_to_install[@]} 个包: ${packages_to_install[*]}"

        # 使用 uv pip 安装包
        install_cmd="source '${venv_path}/bin/activate' && uv pip install -U ${packages_to_install[*]}"

        if [[ "${use_system_venv}" == "1" ]] && [[ "$EUID" -eq 0 ]]; then
            # 系统级：以 root 运行
            timeout 600 bash -c "${install_cmd}" || {
                echo "⚠️  部分包安装失败，但继续"
            }
        else
            # 用户级：以当前用户运行
            timeout 600 bash -c "${install_cmd}" || {
                echo "⚠️  部分包安装失败，但继续"
            }
        fi

        echo "✅ Python 包安装完成"
    fi

    # 输出配置说明
    echo ""
    echo "=========================================="
    echo "Neovim Python 环境配置"
    echo "=========================================="
    echo "虚拟环境位置: ${venv_path}"
    echo ""
    echo "请在 Neovim 配置 (init.lua) 中添加："
    echo ""
    echo "-- 指定 Python 解释器"
    echo "vim.g.python3_host_prog = \"${venv_path}/bin/python\""
    echo ""
    echo "-- 添加虚拟环境 site-packages 到 pythonpath"
    echo "local venv_path = \"${venv_path}\""
    echo "vim.opt.pp:prepend(venv_path .. \"/lib/python*/site-packages\")"
    echo ""
fi

echo ""
echo "=========================================="
echo "Neovim 配置安装完成！"
echo "=========================================="
echo ""
echo "配置文件位置: $NVIM_CONFIG_DIR"
echo ""
echo "下一步："
echo "1. 启动 Neovim: nvim"
echo "2. 如果使用 lazy.nvim，插件会自动安装"
echo "3. 如果使用 vim-plug，运行: :PlugInstall"
echo ""
echo "更新配置："
echo "  cd script_tool_and_config"
echo "  git submodule update --remote dotfiles/nvim"
echo "  然后重新运行此安装脚本"
echo ""

