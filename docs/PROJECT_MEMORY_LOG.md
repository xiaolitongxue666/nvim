# Project Memory Log

按日期追加的变更与问题记录。权威摘要见根目录 [PROJECT_MEMORY.md](../PROJECT_MEMORY.md)。

## 2026-06-03

### 跨平台路径与注释风格优化

- **lua/config/paths.lua**：统一 `config_dir` / `lockfile_path` / `plugins_glob`；`init.lua` 写入 `vim.g.nvim_config_dir`；XDG 候选用 `vim.fs.join`。
- **basic.lua MinGW**：删除 `C:\msys64` 硬编码；按 `MINGW_PREFIX`、`ProgramData`、`NVIM_MINGW_PATHS` 探测。
- **install.sh**：`is_same_directory` 跳过自部署；WSL 检测日志提示 fnm/tree-sitter-cli。
- **注释**：36 个 `lua/plugins/*.lua` 文件头统一三行格式；`README.md` 维护建议补充模板。
- **文档**：`TROUBLE_SHOOT.md` 增加 Windows 编译工具 / luasnip jsregexp 小节；`PROJECT_MEMORY` #21–#24。

### summary-memory（2026-06-03）

- **清理**：仓库内无暂存日志/调试产物/空文件；`docs/install_run.log` 与 `docs/nvim_checkhealth_final.log` 保留作验收证据；`graphify-out/` 在 `.gitignore` 内可 `graphify update .` 再生。
- **冗余**：sha256 无重复文件；`PROJECT_MEMORY` #21+#22 合并为「路径解析栈」。
- **待用户**：`~/.config/nvim.backup.*` 多份历史备份在仓库**外**父目录，需手动清理时保留最近 1–2 份即可。

### Windows + Git Bash 从头测试

- **install.sh 路径转换**：sed 把 `C:/Users/...` 转成 `c/Users/...`（缺 `/c/` 前缀），`ensure_directory` 在仓库内误建 `~/.config/nvim/c/`；改用 `scripts/common.sh` 路径函数 + 绝对路径守卫。
- **Git Bash stdpath 双路径**：无 `XDG_CONFIG_HOME` 时 stdpath 为 `C:\msys64\home\Administrator\AppData\Local\nvim`；PowerShell junction + `~/.bashrc` 设置 XDG；禁用 cmd `mklink`（曾产生 `msys64homeAdministratorAppDataLocalnvim` 错误链接）。
- **collect_plugin_specs**：Windows 反斜杠 glob + 单 spec `{ "name", config }` 被 ipairs 误判，导致 mini.starter 等 config 未执行。
- **mini.starter**：Neovim 0.11 intro / `is_something_shown()` 跳过 autoopen；`shortmess` 加 `I`；`UIEnter` 强制打开。
- **init.lua**：路径自愈（package.path / runtimepath / VimEnter）。
- **验收**：`install.sh` exit 0；`lazy-lock.json` 回填；checkhealth 核心 CLEAN（luasnip jsregexp 可选 ⚠）。

### 后续约束

- 改 `lua/config/lazy.lua` 的 `collect_plugin_specs` 时须同时测 Windows glob 与 `{ "plugin", config }` 简写 spec。
- Windows junction 创建优先 PowerShell，勿在 Git Bash 直接调交互式 `cmd.exe`。
- 新 Git Bash 终端确认 `:echo stdpath('config')` 与 `:echo $XDG_CONFIG_HOME`。

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
