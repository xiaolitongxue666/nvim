# IdeaVim 配置

在 IntelliJ IDEA 系列 IDE（PyCharm、WebStorm、CLion 等）中通过 [IdeaVim](https://github.com/JetBrains/ideavim) 使用与本仓库 Neovim 一致的编辑习惯。

- **选项**：与 [`lua/basic.lua`](../lua/basic.lua) 对齐（IdeaVim 支持的 `set`）
- **键位**：与 [`lua/keybindings.lua`](../lua/keybindings.lua) / [`vscode_neovim/vscode_neovim_init.lua`](../vscode_neovim/vscode_neovim_init.lua) 对齐（Neovim 优先）
- **IDE 功能**：`<Action>(...)` 映射；与 Neovim 冲突的项已改前缀

本目录与仓库根 `init.lua`、Lazy 插件**相互独立**；仅部署 `~/.ideavimrc`。

## 文件结构

```
ideavimrc/
├── .ideavimrc          # IdeaVim 配置
├── install.sh          # 安装脚本（macOS / Linux / Windows Git Bash）
├── install.cmd         # Windows：调用 Git Bash 执行 install.sh
└── README.md
```

## 安装

### 1. 安装 IdeaVim 插件

1. **Settings / Preferences**（Windows/Linux: `Ctrl+Alt+S`，macOS: `Cmd+,`）
2. **Plugins** → 搜索 **IdeaVim** → Install → 重启 IDE

### 2. 部署配置文件

#### 自动安装（推荐）

```bash
cd ~/.config/nvim/ideavimrc
chmod +x install.sh
./install.sh
```

脚本会：

1. 检测操作系统（macOS / Linux / Windows Git Bash）
2. 将 `ideavimrc/.ideavimrc` 链接或复制到 `~/.ideavimrc`（优先符号链接，失败则复制）
3. 备份已有实体文件（`~/.ideavimrc.backup.YYYYMMDD_HHMMSS`）

#### Windows（cmd）

```cmd
cd %USERPROFILE%\.config\nvim\ideavimrc
install.cmd
```

或在 Git Bash：

```bash
cd ~/.config/nvim/ideavimrc
./install.sh
```

`install.cmd` 会查找 `bash` 或环境变量 `NVIM_GIT_BASH`（指向 `bash.exe`），再执行同目录 `install.sh`。

#### 手动安装

```bash
cp ~/.config/nvim/ideavimrc/.ideavimrc ~/.ideavimrc
# 或符号链接
ln -sf ~/.config/nvim/ideavimrc/.ideavimrc ~/.ideavimrc
```

### 环境变量

| 变量 | 默认 | 说明 |
|------|------|------|
| `IDEAVIM_DRY_RUN` | 空 | 设为 `1` 仅打印将执行的操作，不写文件 |
| `IDEAVIM_USE_COPY` | 空 | 设为 `1` 强制复制，不创建符号链接 |
| `IDEAVIM_SKIP_BACKUP` | 空 | 设为 `1` 跳过备份已有 `~/.ideavimrc` |

示例：

```bash
IDEAVIM_DRY_RUN=1 ./install.sh
IDEAVIM_USE_COPY=1 ./install.sh
```

## 配置文件位置

| 用途 | 路径 |
|------|------|
| 用户配置（IDE 读取） | `~/.ideavimrc` |
| Windows | `%USERPROFILE%\.ideavimrc` |
| 仓库源文件 | `~/.config/nvim/ideavimrc/.ideavimrc` |

重载：`R` 或 `:source ~/.ideavimrc`；编辑：`<leader>rc`。

## `basic.lua` → `.ideavimrc` 映射

| `basic.lua` | `.ideavimrc` / 说明 |
|-------------|---------------------|
| UTF-8 | `set encoding` / `fileencoding` |
| `scrolloff` / `sidescrolloff` = 8 | `set scrolloff` / `sidescrolloff` |
| `number` + `relativenumber` | `set number` / `relativenumber` |
| `cursorline` | `set cursorline` |
| `colorcolumn` = 80 | `set colorcolumn=80` |
| tab 4 + `expandtab` | `tabstop` / `shiftwidth` / `expandtab` |
| `ignorecase` + `smartcase` | 同上 |
| `hlsearch` / `incsearch` | 同上 |
| `noshowmode` | `set noshowmode` |
| `autoread` | `set autoread` |
| 有效 `wrap` off（`wo.wrap=false`） | `set nowrap` |
| `whichwrap` | 同上 |
| `hidden`、无 backup/swap | 同上 |
| `splitbelow` / `splitright` | 同上 |
| `list` / `listchars` | 同上 |
| `clipboard=unnamed` | `set clipboard=unnamed,ideaput` |
| BufReadPost 恢复光标 | `au BufReadPost` |

**不在 `.ideavimrc` 中配置**（由 IDE 或 Neovim 单独处理，见 [`vscode_neovim/README.md`](../vscode_neovim/README.md)）：

| `basic.lua` | 说明 |
|-------------|------|
| 代理 / `NVIM_PROXY_URL` | Neovim 子进程；IDE 用自身网络设置 |
| Windows `APPDATA` / MinGW PATH | Neovim/Mason 专用 |
| `signcolumn` | IdeaVim 无等价 `set` |
| `termguicolors` / `showtabline` | IDE 主题与标签栏 |
| `updatetime` | Neovim 专用 |
| `mouse` | basic 未启用；未在 ideavimrc 中 `set mouse` |
| `TextYankPost` 高亮 | Neovim API |
| shell / `loaded_*_provider` | Neovim 专用 |

## 键位分层

### Neovim 习惯（与 keybindings / vscode_neovim 一致）

- Leader：空格
- `i/j/k/l`：方向；`J`/`L`：`b`/`w`；`I`/`K`：5 行
- `<leader>o`：折叠 `za`
- `<leader>i/j/k/l`：窗口焦点（`<C-w>`）
- `<leader>q`：关闭当前编辑器（`<Action>(CloseEditor)`）
- `S`：`:w`；`R`：重载配置；`<leader>rc`：打开 `~/.ideavimrc`

### IDEA 动作（冲突已迁移）

| 功能 | 快捷键 |
|------|--------|
| 文件结构 | `<leader>fo`（原 `<leader>o`） |
| 上一分割 | `<leader>pi`（原 `<leader>i`） |
| 项目视图中选择 | `<leader>ps` 或 `<leader>pw`（原 `<leader>s`） |
| 调试 / 运行 / 停止 | `<leader>d` / `<leader>1` / `<leader>2` / `<leader>0` |
| 重命名 | `<leader>r` |
| 优化导入 | `<leader>oi` |
| 跳转文件 | `<leader>gg` |
| 全局搜索 | `<C-n>` |

完整列表见 [`.ideavimrc`](.ideavimrc) 第 3 节注释。

## Windows 符号链接（可选）

默认先尝试 `ln -sf` 指向仓库内 `.ideavimrc`，失败则自动复制。若需符号链接：

1. Git for Windows 安装时勾选 **Enable symbolic links**
2. `git config --global core.symlinks true`
3. 可选环境变量 `MSYS=winsymlinks:nativestrict`
4. NTFS 分区；必要时以管理员运行 Git Bash

无法配置时：`IDEAVIM_USE_COPY=1 ./install.sh`。

## 验收

```bash
cd ~/.config/nvim/ideavimrc
IDEAVIM_DRY_RUN=1 ./install.sh
./install.sh
```

IDE 内：

1. `:source ~/.ideavimrc` 或按 `R` 无报错
2. `set scrolloff?` 为 8；编辑区不软换行（`nowrap`）
3. `J`/`L` 按词移动；`<leader>o` 折叠；`<leader>fo` 文件结构

## 参考

- [JetBrains/ideavim](https://github.com/JetBrains/ideavim)
- [IdeaVim set commands](https://github.com/JetBrains/ideavim/wiki/set-commands)
- [vscode_neovim](../vscode_neovim/)（同仓库嵌入 Neovim 配置）
