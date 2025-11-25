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

