# Neovim Configuration

基于 Lua 的 Neovim 配置，使用 [lazy.nvim](https://github.com/folke/lazy.nvim) 管理插件。独立 Git 仓库，支持 macOS、Linux、Windows、WSL。

**要求**：Neovim **0.11.0+**、Git、安装脚本依赖 [uv](https://github.com/astral-sh/uv) 与 [fnm](https://github.com/Schniz/fnm)。

## 安装与更新

```bash
git clone <本仓库地址> ~/.config/nvim
cd ~/.config/nvim
chmod +x install.sh
./install.sh
```

更新：`git pull && ./install.sh`

查看当前配置目录：`:echo stdpath('config')`（优先 `$XDG_CONFIG_HOME/nvim` 或 `~/.config/nvim`）。

Windows / `%APPDATA%` / Mason 等问题见 [TROUBLE_SHOOT.md](TROUBLE_SHOOT.md)。

## 文档导航

| 文档 | 内容 |
|------|------|
| [docs/LSP_VIEW_AND_MANAGE.md](docs/LSP_VIEW_AND_MANAGE.md) | LSP 查看、Mason、键位、排错 |
| [TROUBLE_SHOOT.md](TROUBLE_SHOOT.md) | Windows 路径、install.sh、Mason |
| [docs/INVENTORY.md](docs/INVENTORY.md) | 文件/脚本/插件清单（当前基线） |
| [PROJECT_MEMORY.md](PROJECT_MEMORY.md) | 项目记忆（install.sh 同步到各 Agent 配置） |
| [docs/plugin_github_audit.txt](docs/plugin_github_audit.txt) | 当前启用插件的 GitHub 核查原始数据 |
| [ideavimrc/README.md](ideavimrc/README.md) | 可选：IntelliJ IdeaVim |
| `vscode_neovim/` | 可选：VSCode Neovim（`settings.json` 需按本机改路径） |

## 项目结构

```
~/.config/nvim/
├── init.lua                 # 入口：basic → keybindings → window_control → lazy
├── install.sh               # 安装/依赖/路径注入
├── lua/
│   ├── basic.lua
│   ├── keybindings.lua
│   ├── window_control.lua
│   ├── config/lazy.lua
│   └── plugins/             # 36 个插件规格文件
├── scripts/
│   ├── common.sh            # 日志/目录/超时工具
│   └── bash.cmd             # Windows toggleterm 用 Git Bash（可配置）
├── docs/
├── TROUBLE_SHOOT.md
├── PROJECT_MEMORY.md
└── lazy-lock.json
```

## 启动流程

```mermaid
flowchart TD
    A[启动 Neovim] --> B[init.lua]
    B --> C[basic.lua]
    B --> D[keybindings.lua]
    B --> E[window_control]
    B --> F[config.lazy]
    F --> G[lazy.setup]
    G --> H[plugins/*.lua]
    H --> I[LSP / Treesitter / CMP / UI]
```

## 核心模块

| 模块 | 职责 |
|------|------|
| `basic.lua` | 编码、UI、搜索、剪贴板、provider |
| `keybindings.lua` | Leader、hjkl 重映射、窗口、保存 |
| `window_control.lua` | 插件窗口智能缩放 |
| `config/lazy.lua` | lazy.nvim 引导 |
| `plugins/*.lua` | 按功能拆分的插件配置 |

## 快捷键概要

Leader 为 `<Space>`。光标：`i/k/j/l` 对应上/下/左/右（与 Vim 默认不同）。

| 类别 | 键位 | 说明 |
|------|------|------|
| 文件 | `S` | 保存 |
| 文件 | `<leader>Q` | 保存并退出 |
| 终端 | `<leader>/` | ToggleTerm（仅 toggleterm 一处定义） |
| 树/大纲 | `<leader>e` / `<leader>O` | neo-tree / outline |
| LSP | `D` | 悬停（LSP buffer；全局 `K` 为下移 5 行） |
| LSP | `<leader>cf` | 格式化（conform，与保存时一致） |
| Mason | `<leader>cm` | Mason |
| 补全 | `Tab` / `Shift-Tab` | cmp（含 snippet 跳转） |
| 补全菜单 | `<C-f>` / `<C-b>` | 滚动文档（插入模式） |

完整列表：`:WhichKey` 或各 `lua/plugins/*.lua` 内 `keys`/`mappings`。

LSP 与 Mason 详见 [docs/LSP_VIEW_AND_MANAGE.md](docs/LSP_VIEW_AND_MANAGE.md)。

## 插件 GitHub 状态

核查时间：2026-05-19（`gh api`，原始输出见 [docs/plugin_github_audit.txt](docs/plugin_github_audit.txt)）。

### 当前状态（启用插件）

| 仓库 | 状态 | 建议 |
|------|------|------|
| `mason-org/mason.nvim` / `mason-org/mason-lspconfig.nvim` | 已切换到上游组织 | 与当前上游一致 |
| `neovim-treesitter/nvim-treesitter` | 已切换到活跃仓库 | 分支已改为 `main` |
| [folke/snacks.nvim](https://github.com/folke/snacks.nvim) | 已启用 input/picker | 替代 archived 的 dressing 选择/输入 UI |
| [numToStr/Comment.nvim](https://github.com/numToStr/Comment.nvim) | 最近推送 2024-08 | 仍可用；长期可观察迁移方案 |
| [saadparwaiz1/cmp_luasnip](https://github.com/saadparwaiz1/cmp_luasnip) | 最近推送 2024-11 | 仍可用；关注 cmp/LuaSnip 大版本 |
| [akinsho/bufferline.nvim](https://github.com/akinsho/bufferline.nvim) / [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) | 2025 初后较少提交 | 功能正常，升级前看 changelog |
| [nvim-pack/nvim-spectre](https://github.com/nvim-pack/nvim-spectre) | 2025-05 后较少提交 | 仍可用 |

### 历史归档仓库（已移除或替换）

- `folke/neodev.nvim` → 使用 `folke/lazydev.nvim`
- `nvim-treesitter/nvim-treesitter` → 使用 `neovim-treesitter/nvim-treesitter`
- `stevearc/dressing.nvim` → 使用 `folke/snacks.nvim`（input/picker）

## 配置冲突与治理

以下项已在本次整治中**处理**或**文档化**；机制说明便于后续维护。

| 优先级 | 冲突 | 机制 | 处理 |
|--------|------|------|------|
| **高** | `<Tab>` cmp vs LuaSnip | 两处 `i` 模式 Tab 映射 | LuaSnip 的 `keys` 已移除，由 cmp 统一 |
| **高** | `<C-f>`/`<C-b>` cmp vs noice | 插入模式同键 | noice 滚动限制为 `n`/`s`，cmp 保留 `i` |
| **高** | Python `pyright` + `ruff_lsp` | 双 LSP 诊断 | pyright 关闭 publishDiagnostics，ruff 负责 lint |
| **高** | 保存 conform vs `<leader>cf` LSP format | 不同格式化路径 | `<leader>cf` 改为 `conform.format()` |
| **高** | `<leader>/` 三处定义 | keybindings + toggleterm ×2 | keybindings 与 toggleterm 重复映射已删，仅 lazy `keys` |
| **中** | mason-lspconfig 默认 handler | 空 `{}` 二次 `vim.lsp.enable` | handler 改为 no-op，由 lspconfig 主配置 enable |
| **中** | neo-tree `S` vs 全局保存 `S` | 树内水平分屏占键 | 树内改为 `s` 打开分屏 |
| **中** | neo-tree `document_symbols` + outline | 双符号侧栏 | 已移除 neo-tree 的 `document_symbols`，保留 outline |
| **中** | hardtime 在特殊 UI buffer 抢键 | 侧栏/选择器体验受影响 | 已加入 `neo-tree`/`mason`/`DressingSelect` 白名单 |
| **低** | `[b`/`]b` 与 `<leader>[`/`]` | 别名 | 保留，which-key 说明即可 |
| **低** | bufferline + lualine 诊断 | 三处展示 | 可关其一（建议保留 buffer 内 virtual text） |

验证：

```vim
:verbose imap <Tab>
:verbose imap <C-f>
:verbose nmap <leader>/
:lua print(vim.inspect(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients())))
```

## 维护建议

1. `opencode` 的 `go`/`goo` 可迁移到 `<leader>a…` 前缀，减少与内置 `g` 序列冲突。
2. `vscode_neovim/settings.json` 中平台路径保持本机化，提交前避免写入敏感本地路径。
3. 定期执行 `:Lazy update`、`:MasonUpdate`、`:checkhealth`。

## 健康检查

```vim
:checkhealth
```

保存日志（无额外脚本）：

```bash
nvim --headless --cmd "redir! > nvim_checkhealth.log" -c "checkhealth" -c "redir END" -c "qa!"
```

缺失工具可由 `./install.sh` 协助安装；代理见 `basic.lua` 中 `NVIM_PROXY_URL` / `http_proxy`。

## 维护

- 插件按 `lua/plugins/<功能>_<插件名>.lua` 命名。
- 改插件后：`:Lazy sync`；改 LSP 工具：`:MasonUpdate`。
- 整治后更新图谱：`graphify update .`（若使用 graphify）。

## 参考链接

- [Neovim 文档](https://neovim.io/doc/user/)
- [lazy.nvim](https://github.com/folke/lazy.nvim)
- [本仓库](https://github.com/xiaolitongxue666/nvim)
