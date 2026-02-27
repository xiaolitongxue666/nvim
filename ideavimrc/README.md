# IdeaVim 配置

IdeaVim 是 IntelliJ IDEA 系列 IDE（包括 PyCharm、WebStorm、CLion 等）的 Vim 模拟插件，让您可以在 IDE 中使用 Vim 的编辑方式。

## 配置文件结构

```
ideavimrc/
├── .ideavimrc          # IdeaVim 配置文件
├── install.sh          # 自动安装和配置脚本（支持多平台，包含配置同步和备份）
└── README.md           # 本文件
```

## 安装方法

### 1. 安装 IdeaVim 插件

在 IntelliJ IDEA / PyCharm / WebStorm 等 IDE 中：

1. 打开 **Settings / Preferences** (Windows/Linux: `Ctrl+Alt+S`, macOS: `Cmd+,`)
2. 进入 **Plugins**
3. 搜索 "IdeaVim"
4. 点击 **Install** 安装插件
5. 重启 IDE

### 2. 安装配置文件

#### 自动安装（推荐）

使用安装脚本自动检测系统并安装对应配置（包含自动备份）：

```bash
cd ~/.config/nvim/ideavimrc
chmod +x install.sh
./install.sh
```

安装脚本会自动：
- 检测操作系统（macOS/Linux/Windows）
- 备份现有配置文件（如果存在）
- 复制配置文件到 `~/.ideavimrc`

#### 手动安装

```bash
# 复制配置文件到用户目录
cp ~/.config/nvim/ideavimrc/.ideavimrc ~/.ideavimrc
```

## 配置文件位置

- **配置文件**: `~/.ideavimrc`
- **项目内路径**: `~/.config/nvim/ideavimrc/.ideavimrc`

## Windows 符号链接配置

在 Windows 上使用 Git Bash 创建符号链接需要额外配置：

### 1. 重新安装 Git Bash 并勾选 Enable link

在安装 Git for Windows 时，确保勾选 "Enable symbolic links" 选项。

### 2. 确保 Git 的配置中启用了符号链接支持

```shell
git config --get core.symlinks
git config --global core.symlinks true
```

### 3. 运行 Git Bash 作为管理员

以管理员权限运行 Git Bash，以便创建符号链接。

### 4. Windows 10 开发者模式

在 Windows 10 中，您可以启用开发者模式，这样可以更轻松地创建符号链接：

1. 打开"设置"
2. 转到"更新和安全"
3. 选择"对于开发人员"
4. 启用"开发者模式"

### 5. 确保磁盘分区格式为 NTFS

符号链接功能仅在 NTFS 文件系统上可用。

### 6. 添加环境变量

#### 添加环境变量步骤

1. **打开系统属性**：
   - 右键单击"此电脑"或"计算机"图标，选择"属性"
   - 在左侧菜单中，点击"高级系统设置"

2. **打开环境变量设置**：
   - 在"系统属性"窗口中，点击"环境变量"按钮

3. **添加新环境变量**：
   - 在"环境变量"窗口中，您会看到两个部分：用户变量和系统变量
   - 如果您希望为所有用户添加变量，请在"系统变量"部分点击"新建"按钮。如果只想为当前用户添加变量，请在"用户变量"部分点击"新建"按钮

4. **输入变量名和变量值**：
   - 在弹出的对话框中，输入以下内容：
     - **变量名**：`MSYS`
     - **变量值**：`winsymlinks:nativestrict`
   - 点击"确定"保存

5. **确认更改**：
   - 关闭所有窗口，确保更改已保存

6. **重新启动 Git Bash**：
   - 关闭并重新打开 Git Bash，以使新环境变量生效

#### 验证环境变量

您可以通过在 Git Bash 中运行以下命令来验证环境变量是否已成功添加：

```bash
echo $MSYS
```

如果输出为 `winsymlinks:nativestrict`，则表示环境变量已成功设置。

## 配置说明

### 主要特性

- **Vim 键位映射**: 完整的 Vim 编辑体验
- **IDEA 动作集成**: 将 Vim 命令映射到 IDEA 功能（如调试、重构、跳转等）
- **自定义 Leader 键**: 空格键作为 Leader 键
- **窗口管理**: 支持分屏、窗口切换等操作
- **代码导航**: 快速跳转、搜索、书签等功能

### 常用快捷键

- `<LEADER>rc`: 打开配置文件
- `R`: 重载配置文件
- `<LEADER>d`: 调试
- `<LEADER>r`: 重命名元素
- `<LEADER>oi`: 优化导入
- `<LEADER>q`: 关闭编辑器
- `<LEADER>1`: 运行
- `<LEADER>2`: 调试
- `<LEADER>0`: 停止

更多快捷键请查看 `.ideavimrc` 文件中的注释。

## 重新加载配置

在 IDE 中，您可以：

1. 使用快捷键 `R` 重载配置
2. 或使用命令 `:source ~/.ideavimrc`

## 参考链接

- [IdeaVim GitHub](https://github.com/JetBrains/ideavim)
- [IdeaVim 官方文档](https://github.com/JetBrains/ideavim/wiki)
- [参考配置 1](https://github.com/OptimusCrime/ideavim/blob/main/ideavimrc)
- [参考配置 2](https://www.cyberwizard.io/posts/the-ultimate-ideavim-setup/)

