# VSCode Neovim / Cursor 配置

在 [VS Code](https://code.visualstudio.com/) 或 [Cursor](https://cursor.com/) 中通过 [vscode-neovim](https://github.com/vscode-neovim/vscode-neovim) 嵌入 Neovim，使用本目录的独立 init 与编辑器设置。

本目录与仓库根目录的 Neovim 配置（`init.lua`、Lazy 插件等）**相互独立**；vscode-neovim 只会加载 `vscode_neovim_init.lua`，不会加载主 `init.lua`。

## 文件结构

```
vscode_neovim/
├── vscode_neovim_init.lua   # Neovim init（vim.g.vscode 分支）
├── settings.json            # 合并到编辑器 User/settings.json 的模板（无机器路径）
├── install.sh               # 安装脚本（macOS / Linux / Windows Git Bash）
├── install.cmd              # Windows：调用 Git Bash 执行 install.sh
└── README.md
```

## 依赖

- Neovim **0.10+**（建议先完成仓库根目录 `./install.sh`）
- **Windows**：Git Bash 中运行 `install.sh`（或 `install.cmd`）
- 编辑器 CLI 在 PATH 中：
  - 默认 **Cursor**：`cursor`
  - 或 **VS Code**：`code`（通过环境变量切换）
- `python3` 或 `python`（合并 JSON 设置）

在 Cursor / VS Code 命令面板执行 **Shell Command: Install 'cursor' command in PATH**（或 `code`）以便脚本安装扩展。

## 安装

### 自动安装（推荐）

```bash
cd ~/.config/nvim/vscode_neovim
chmod +x install.sh
./install.sh
```

脚本会：

1. 检测操作系统（macOS / Linux / Windows Git Bash）
2. 默认目标 **Cursor**；合并 `settings.json` 到 Cursor 的 `User/settings.json`
3. 按本机路径写入 `vscode-neovim.neovimInitVimPaths.{win32,darwin,linux}`
4. 备份已有 `settings.json`（若存在）
5. 安装 Marketplace 扩展 `asvetliakov.vscode-neovim`（必需）
6. 默认安装 `llvm-vs-code-extensions.vscode-clangd`（C/C++ 语言服务，与主配置 Mason `clangd` 对齐；可用 `VSCODE_NEOVIM_SKIP_LANG_EXTENSIONS=1` 跳过）
7. 检查 `nvim` 版本并尝试 headless 加载 init

### 使用 VS Code 而非 Cursor

```bash
VSCODE_NEOVIM_EDITOR=code ./install.sh
```

### 环境变量

| 变量 | 默认 | 说明 |
|------|------|------|
| `VSCODE_NEOVIM_EDITOR` | `cursor` | `cursor` 或 `code` |
| `VSCODE_NEOVIM_DRY_RUN` | 空 | 设为 `1` 仅打印将执行的操作 |
| `VSCODE_NEOVIM_SKIP_EXTENSION` | 空 | 设为 `1` 跳过扩展安装 |
| `VSCODE_NEOVIM_SKIP_LANG_EXTENSIONS` | 空 | 设为 `1` 跳过 clangd 等语言扩展 |
| `VSCODE_NEOVIM_SKIP_NEOVIM_CHECK` | 空 | 设为 `1` 跳过 nvim 版本检查 |

### Windows

```cmd
cd %USERPROFILE%\.config\nvim\vscode_neovim
install.cmd
```

或在 Git Bash：

```bash
cd ~/.config/nvim/vscode_neovim
./install.sh
```

`install.cmd` 会查找 `bash` 或环境变量 `NVIM_GIT_BASH`（指向 `bash.exe`），再执行同目录 `install.sh`。

**路径注意**

- Windows 下 `neovimInitVimPaths.win32` 使用反斜杠路径，由脚本生成并正确 JSON 转义。
- 若 `%APPDATA%` 在 Git Bash 中未展开，脚本会尝试通过 `cmd.exe` 或 `USERPROFILE` 解析。
- WSL 用户若要在 Windows 版 VS Code 中使用 WSL 内的 `nvim`，需在编辑器设置中手动配置 `vscode-neovim.useWSL` 等（见官方 wiki）。

## 安装后的设置位置

| 编辑器 | macOS | Linux | Windows |
|--------|-------|-------|---------|
| Cursor | `~/Library/Application Support/Cursor/User/settings.json` | `$XDG_CONFIG_HOME/Cursor/User/settings.json` | `%APPDATA%/Cursor/User/settings.json` |
| VS Code | `~/Library/Application Support/Code/User/settings.json` | `$XDG_CONFIG_HOME/Code/User/settings.json` | `%APPDATA%/Code/User/settings.json` |

## 生效

1. 在 Cursor / VS Code 中执行 **Developer: Reload Window**
2. 确认扩展 **VSCode Neovim** 已启用
3. 若异常，运行 **Neovim: Restart Extension** 并查看 Output → `vscode-neovim logs`

## 与主 Neovim 配置的关系

| 场景 | 使用的配置 |
|------|------------|
| 终端 / GUI `nvim` | 仓库根 `init.lua` + `lua/plugins/` |
| Cursor / VS Code + vscode-neovim | `vscode_neovim/vscode_neovim_init.lua` |

`vscode_neovim_init.lua` 通过 `require("basic")` 加载与主配置相同的 `lua/basic.lua`，避免两处手写重复。仅对 VSCode 嵌入层做少量覆盖（如 `showtabline`、`mouse`）。

### `basic.lua` → vscode_neovim 映射

| `basic.lua` 选项 | Neovim 层（`require("basic")`） | Cursor/VS Code 层（`settings.json`） |
|------------------|--------------------------------|--------------------------------------|
| `scrolloff` / `sidescrolloff` = 8 | 生效 | `editor.cursorSurroundingLines`: 8 |
| `number` + `relativenumber` | 生效 | `editor.lineNumbers`: `"relative"` |
| `cursorline` | 生效 | `editor.renderLineHighlight`: `"line"` |
| `colorcolumn` = 80 | 生效 | `editor.rulers`: [80] |
| `tabstop` / `shiftwidth` / `expandtab` | 生效 | `editor.tabSize`: 4, `editor.insertSpaces`: true, `editor.detectIndentation`: false |
| `wrap` / `wo.wrap` | 生效 | `editor.wordWrap`: `"off"` |
| `ignorecase` + `smartcase` | 生效 | `search.smartCase`: true |
| `list` / `listchars` | 生效 | `editor.renderWhitespace`: `"boundary"` |
| `hlsearch` / `incsearch` | 生效（Normal 模式搜索） | —（由 Neovim 层处理） |
| `showtabline` = 2 | VSCode 下覆盖为 0 | 使用编辑器自带标签栏 |
| `mouse`（主配置未启用） | VSCode 下 `mouse` 置空 | — |
| 代理 / Windows PATH / APPDATA | `basic.lua` 启动逻辑 | — |
| `clipboard` / `TextYankPost` | `basic.lua` | —（扩展与系统剪贴板协同） |
| `autoread` | `basic.lua` | 无等价项；依赖编辑器文件监视 |

安装脚本合并 `settings.json` 时写入 `vscode-neovim.neovimInitVimPaths.*`（不含机器路径的模板见仓库内 `settings.json`）。

官方建议 vscode 环境使用轻量 init，避免 LSP、高亮、文件树等与 VS Code 重复的插件。本仓库**不**在嵌入 init 中加载 `lspconfig`，而是用编辑器扩展提供语言服务，Neovim 侧仅映射快捷键。

### LSP 导航键位（与主配置 `lsp_server_nvim-lspconfig.lua` 对齐）

| 键位 | 终端 `nvim` | Cursor / VS Code（`vscode_neovim_init.lua`） |
|------|-------------|---------------------------------------------|
| `gd` | `vim.lsp.buf.definition` | `editor.action.revealDefinition` |
| `gD` | `vim.lsp.buf.declaration` | `editor.action.revealDeclaration` |
| `gr` | `vim.lsp.buf.references` | `editor.action.goToReferences` |
| `gI` | `vim.lsp.buf.implementation` | `editor.action.goToImplementation` |
| `gy` | `vim.lsp.buf.type_definition` | `editor.action.goToTypeDefinition` |
| `D` | `vim.lsp.buf.hover` | `editor.action.showHover` |
| `<leader>cr` | `vim.lsp.buf.rename` | `editor.action.rename` |
| `<leader>ca` | `vim.lsp.buf.code_action` | `editor.action.quickFix` |
| `<leader>cf` | conform 格式化 | `editor.action.formatDocument` |

修改上表键位时：终端侧改 `lua/plugins/lsp_server_nvim-lspconfig.lua`，嵌入侧改 `vscode_neovim_init.lua` 中 `VSCodeNotify(...)` 映射。

**C/C++**：需安装 **clangd** 扩展（安装脚本默认安装）。macOS 需系统有 `clangd`（Xcode CLT 或 `brew install llvm`）。改键位或扩展后执行 **Developer: Reload Window**。

### macOS 注意

- `install.sh` 须为 **LF** 行尾；若 `./install.sh` 报 `env: bash\r`，在仓库内执行 `sed -i '' 's/\r$//' install.sh` 后重试。
- 与 Windows 相同：安装脚本会写入三个 `neovimInitVimPaths.*` 键；若使用 Settings Sync，注意 `win32` 勿被 Mac 路径覆盖（见主 [README.md](../README.md) 维护建议）。

## 参考

- [vscode-neovim](https://github.com/vscode-neovim/vscode-neovim)
- [Marketplace: asvetliakov.vscode-neovim](https://marketplace.visualstudio.com/items?itemName=asvetliakov.vscode-neovim)
- 仓库根目录 [install.sh](../install.sh)（Neovim / Python / Node 环境）
