# Neovim Config — Claude Project Context

> Auto-synced from PROJECT_MEMORY.md by install.sh at 2026-06-02T05:18:28Z. Edit PROJECT_MEMORY.md instead.


## 2026-05-21

### 今日已发生的修改

- **vscode_neovim/**：`vscode_neovim_init.lua` 改为 `require("basic")`；`settings.json` 去除硬编码 `neovimInitVimPaths` 并补充与 basic 对齐的 editor 项；新增 README + `install.sh`/`install.cmd`（默认 Cursor，跨平台合并用户设置）。
- **ideavimrc/**：`.ideavimrc` 精简并与 `lua/basic.lua`、键位策略对齐；README 与 `install.sh` 重写；新增 `install.cmd`。
- **主项目文档**：`README.md`（跨编辑器小节、结构树、维护建议）、`docs/INVENTORY.md`、`TROUBLE_SHOOT.md`（子安装排错）已同步。
- **macOS vscode-neovim 落地**：在 Cursor/VS Code 执行子目录 `install.sh`（Cursor + `VSCODE_NEOVIM_EDITOR=code` 各一次）；`install.sh` 修正 CRLF（macOS 须 LF）；默认额外安装 **clangd** 扩展。
- **嵌入 LSP 导航**：`vscode_neovim_init.lua` 增加 `gd`/`gD`/`gr`/`gI`/`gy`/`D` 及 `<leader>cr|ca|cf`，经 `VSCodeNotify` 对齐 `lsp_server_nvim-lspconfig.lua`（不加载 lspconfig，语言服务由编辑器扩展提供）。

### 后续执行约束（记忆化）

- 跨编辑器**选项**变更优先改 `lua/basic.lua`，再核对 vscode 嵌入覆盖与 ideavim `set` 映射表（见子 README）。
- 提交前 `vscode_neovim/settings.json` 不得含本机 `neovimInitVimPaths`。
- 子目录安装脚本或 Windows/Git Bash 行为变更时，同步主 `README.md`、`docs/INVENTORY.md`、`TROUBLE_SHOOT.md`。
- **LSP 键位双份维护**：终端 `gd` 等 → `lua/plugins/lsp_server_nvim-lspconfig.lua`；Cursor/VS Code → `vscode_neovim_init.lua` 的 `VSCodeNotify`；改一处须核对另一处与子 README 键位表。
- **vscode-neovim 语言服务**：不在嵌入 init 加载 Mason/lspconfig；C/C++ 依赖编辑器 **clangd** 扩展（`install.sh` 默认安装，可用 `VSCODE_NEOVIM_SKIP_LANG_EXTENSIONS=1` 跳过）。
- **macOS**：`vscode_neovim/install.sh` 保持 LF；`./install.sh` 失败时检查 CRLF 或改用 `bash install.sh`。
- **Settings Sync**：mac 安装会写入三平台 `neovimInitVimPaths.*`；若同步到 Windows 导致 `win32` 路径错误，在 Windows 重跑 `install.cmd`。

## 2026-05-19

### 今日已发生的修改（基于仓库当前状态）

- 文档层面：
  - `README.md` 已更新，包含插件状态核查、冲突治理条目与维护建议。
  - `docs/INVENTORY.md` 新增并记录仓库基线清单。
  - `docs/plugin_github_audit.txt` 新增并记录启用插件的 GitHub 核查原始数据。
- 配置与脚本层面：
  - `install.sh`、`init.lua`、`lazy-lock.json` 存在变更。
  - `scripts/common.sh`、`scripts/bash.cmd`、`scripts/audit_plugins.sh` 已出现于仓库当前工作区。
- 插件拆分层面：
  - `lua/plugins/` 下已新增多份按功能拆分的插件配置文件（补全、LSP、UI、终端、会话等）。
- 规则与忽略：
  - 新增项目级规则：`.cursor/rules/cross-os-wsl-compat.mdc`（多 OS + WSL 兼容约束）。
  - `.gitignore` 已更新，允许追踪 `.cursor/rules/*.mdc`，并补充 Python 缓存忽略。

### 今日识别到的问题（基于现有文档）

- 键位冲突历史：`<Tab>`、`<C-f>/<C-b>`、`<leader>/` 曾出现重复或冲突定义。
- 格式化链路不一致历史：保存自动格式化与手动格式化入口曾走不同路径。
- LSP 诊断重复历史：Python 侧 `pyright` 与 `ruff_lsp` 曾产生重复诊断。
- 插件生态迁移：部分历史依赖仓库已归档或迁移（如 `neodev`、`dressing` 的替代方案已落地）。
- 平台路径差异：Windows `%APPDATA%`、WSL、`XDG_CONFIG_HOME` 路径语义不同，需持续避免硬编码。

### 后续执行约束（记忆化）

- 新增涉及路径、shell、安装流程的改动时，默认同时验证 Windows + WSL 场景。
- 新增项目规则时优先放在 `.cursor/rules/*.mdc`，保证可版本化。
- 变更完成后优先维护 `README.md`、`TROUBLE_SHOOT.md`、本文件三处一致性。

### 安装更新与健康清零（2026-05-19 会话）

**已完成流程**

1. `./install.sh`：部署配置；uv 维护 `venv/nvim-python`（pynvim、pyright、ruff-lsp 等）；fnm 维护 Node LTS 与全局 `neovim`、`tree-sitter-cli`、`pnpm`。
2. 无头 `Lazy! update`：更新 lazy.nvim 管理的插件。
3. 无头 `checkhealth`：修复至严格口径 0 条 ERROR/WARNING；证据见 `docs/nvim_checkhealth_final.log`。

**关键修复**

- `nvim-treesitter`：`Lazy update` 将 `main` 拉到需 Neovim 0.12+ 的 rewrite；本机 0.11.5 改回上游兼容分支 **`master`**（`lua/plugins/code_highlight_nvim-treesitter.lua`，`lazy-lock.json` 已同步）。
- WSL：`tree-sitter` 勿用 Windows npm 路径；无头前 `eval "$(fnm env --use-on-cd)"`，必要时 `npm install -g tree-sitter-cli`（Linux 侧）。

**无头模式经验（详见 `.cursor/rules/headless-testing.mdc`）**

- 必须 `-u init.lua`；结束用 `-c "qa!"`。
- 健康检查落盘优先：`-c "checkhealth" -c "w! docs/nvim_checkhealth_final.log"`（`redir` 在 headless 下常只得到标题）。
- 插件未就绪时用 `vim.wait` + `pcall(require, ...)` 再跑 `checkhealth`。
- `Lazy update` 后若 Mason 仍在安装，立即 `qa!` 会中止安装并报错；需留足时间或分开执行。
- 验收 grep 用 `^- ERROR|^- WARNING|❌|⚠`，避免把 treesitter 图例里的 `x) errors found in the query` 误判为失败。

**标准复现命令**

```bash
cd ~/.config/nvim && eval "$(fnm env --use-on-cd)" && ./install.sh
nvim --headless -u init.lua -c "Lazy! update" -c "qa!"
nvim --headless -u init.lua \
  -c "lua vim.wait(25000, function() return pcall(require,'nvim-treesitter.configs') end)" \
  -c "checkhealth" -c "w! docs/nvim_checkhealth_final.log" -c "qa!"
```
