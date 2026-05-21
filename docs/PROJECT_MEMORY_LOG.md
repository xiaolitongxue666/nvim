# Project Memory Log

按日期追加的变更与问题记录。权威摘要见根目录 [PROJECT_MEMORY.md](../PROJECT_MEMORY.md)。

## 2026-05-21

### 今日已发生的修改

- **vscode_neovim/**：`vscode_neovim_init.lua` 改为 `require("basic")`；`settings.json` 去除硬编码 `neovimInitVimPaths` 并补充与 basic 对齐的 editor 项；新增 README + `install.sh`/`install.cmd`（默认 Cursor，跨平台合并用户设置）。
- **ideavimrc/**：`.ideavimrc` 精简并与 `lua/basic.lua`、键位策略对齐；README 与 `install.sh` 重写；新增 `install.cmd`。
- **主项目文档**：`README.md`（跨编辑器小节、结构树、维护建议）、`docs/INVENTORY.md`、`TROUBLE_SHOOT.md`（子安装排错）已同步。
- **macOS vscode-neovim**：子目录 `install.sh` 落地 Cursor/VS Code；`install.sh` LF 行尾与默认 **clangd** 扩展；`vscode_neovim_init.lua` 增加 LSP 导航 `VSCodeNotify` 键位（与 `lsp_server_nvim-lspconfig.lua` 对齐）。

### 后续执行约束（记忆化）

- 跨编辑器**选项**变更优先改 `lua/basic.lua`，再核对 vscode 嵌入覆盖与 ideavim `set` 映射表（见子 README）。
- 提交前 `vscode_neovim/settings.json` 不得含本机 `neovimInitVimPaths`。
- 子目录安装脚本或 Windows/Git Bash 行为变更时，同步主 `README.md`、`docs/INVENTORY.md`、`TROUBLE_SHOOT.md`。
- LSP 键位：终端 `lsp_server_nvim-lspconfig.lua` ↔ 嵌入 `vscode_neovim_init.lua`；语言服务由编辑器扩展（clangd）提供，不加载 lspconfig。

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
- 变更完成后优先维护 `README.md`、`TROUBLE_SHOOT.md`、`PROJECT_MEMORY.md` 三处一致性。

### 安装更新与健康清零（同日晚间）

- 执行 `./install.sh` → 无头 `Lazy! update` → 无头 `checkhealth`，严格口径全绿。
- 新增规则 [`.cursor/rules/headless-testing.mdc`](../.cursor/rules/headless-testing.mdc)；`nvim-treesitter` 钉在 `master`（0.11 兼容）；证据 `docs/nvim_checkhealth_final.log`。
- 经验摘要已写入 `PROJECT_MEMORY.md`「无头模式经验」小节。
