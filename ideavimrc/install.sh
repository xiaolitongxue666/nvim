#!/bin/bash

# IdeaVim 配置安装脚本
# 支持 macOS、Linux、Windows 系统

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

echo "=========================================="
echo "IdeaVim 配置安装脚本"
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

# Windows 特殊提示
if [[ "$PLATFORM" == "windows" ]]; then
    echo "=========================================="
    echo "Windows 符号链接配置提示"
    echo "=========================================="
    echo "在 Windows 上使用 Git Bash 创建符号链接需要额外配置："
    echo ""
    echo "1. 重新安装 Git Bash 并勾选 'Enable symbolic links'"
    echo "2. 配置 Git 启用符号链接支持："
    echo "   git config --global core.symlinks true"
    echo "3. 运行 Git Bash 作为管理员"
    echo "4. 启用 Windows 10 开发者模式"
    echo "5. 确保磁盘分区格式为 NTFS"
    echo "6. 添加环境变量 MSYS=winsymlinks:nativestrict"
    echo ""
    echo "详细说明请参考 README.md"
    echo ""
    read -p "是否已配置符号链接支持？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "警告: 符号链接可能无法正常工作，将使用复制方式"
        USE_COPY=true
    fi
fi

# 同步配置文件
echo ""
echo "=========================================="
echo "同步配置文件"
echo "=========================================="

IDEAVIMRC_FILE="$HOME/.ideavimrc"

# 备份现有配置（如果存在）
if [ -f "$IDEAVIMRC_FILE" ] && [ ! -L "$IDEAVIMRC_FILE" ]; then
    BACKUP_FILE="$IDEAVIMRC_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$IDEAVIMRC_FILE" "$BACKUP_FILE"
    echo "✅ 已备份现有配置到: $BACKUP_FILE"
fi

# 复制配置文件
if [ -f "$SCRIPT_DIR/.ideavimrc" ]; then
    if [[ "$PLATFORM" == "windows" ]] && [[ "$USE_COPY" != "true" ]] && command -v ln &> /dev/null; then
        # Windows 上尝试使用符号链接
        if [ -f "$IDEAVIMRC_FILE" ] && [ ! -L "$IDEAVIMRC_FILE" ]; then
            rm "$IDEAVIMRC_FILE"
        fi
        ln -sf "$SCRIPT_DIR/.ideavimrc" "$IDEAVIMRC_FILE" 2>/dev/null && echo "✅ 已创建符号链接: $IDEAVIMRC_FILE" || {
            echo "⚠️  符号链接创建失败，使用复制方式"
            cp "$SCRIPT_DIR/.ideavimrc" "$IDEAVIMRC_FILE"
            echo "✅ 已复制配置文件到: $IDEAVIMRC_FILE"
        }
    else
        # 其他平台或 Windows 上使用复制方式
        cp "$SCRIPT_DIR/.ideavimrc" "$IDEAVIMRC_FILE"
        echo "✅ 已复制配置文件到: $IDEAVIMRC_FILE"
    fi
else
    echo "❌ 警告: 未找到配置文件: $SCRIPT_DIR/.ideavimrc"
    exit 1
fi

echo ""
echo "=========================================="
echo "IdeaVim 配置安装完成！"
echo "=========================================="
echo ""
echo "配置文件位置: $IDEAVIMRC_FILE"
echo ""
echo "下一步："
echo "1. 在 IntelliJ IDEA / PyCharm / WebStorm 等 IDE 中安装 IdeaVim 插件"
echo "2. 重启 IDE 使配置生效"
echo "3. 在 IDE 中按 <LEADER>rc 可以快速打开配置文件"
echo ""

