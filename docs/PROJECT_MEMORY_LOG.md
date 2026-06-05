# Project Memory Log

按日期追加的变更与问题记录。权威摘要见根目录 [PROJECT_MEMORY.md](../PROJECT_MEMORY.md)。

## 2026-06-03

### macOS 安装与无头验收（summary-memory）

- **环境**：NVIM v0.11.6、uv 0.9.10、fnm 1.38.1、Node v20.20.2；`eval "$(fnm env --use-on-cd)"` 后验收。
- **结果**：`./install.sh` exit 0；`bash scripts/headless_validate.sh` exit 0；`docs/nvim_checkhealth_final.log` 务实 grep 无 ERROR/可修复 WARNING。
- **log 白名单项**：`vim.health` 报 `Missing user config file: nvim/init.lua`；`terminal` 缺 `key_backspace`/`key_dc` terminfo（headless/dumb 预期）。
- **运维**：`./scripts/headless_validate.sh` 无可执行位时用 `bash`；`install.sh` step 7 在 `~/.config/` 外生成 `nvim.backup.*`（本机曾累积多份，宜手动保留最近 1–2 份）。

### Win10/Win11 统一流程 + 无头 checkhealth

- **install.cmd**（根目录）、**scripts/headless_validate.sh**（Lazy + Mason sleep + 务实 grep）。
- **install.sh**：`ensure_windows_user_env`、`setup_default_proxy`（原 `setup_windows_proxy` 已废弃）、`cleanup_legacy_packer`、stdpath 跳过 `%` 候选；末尾可选无头验收。
- **init.lua**：`vim.fs.joinpath or vim.fs.join`（0.12）。
- **LuaSnip**：Windows MinGW make 探测构建 jsregexp。
- **文档**：TROUBLE_SHOOT 迁移/白名单；headless-testing.mdc；PROJECT_MEMORY #25–#28。

### 跨平台路径与注释风格优化

- **lua/config/paths.lua**：统一 `config_dir` / `lockfile_path` / `plugins_glob`；`init.lua` 写入 `vim.g.nvim_config_dir`；XDG 候选用 `vim.fs.join`。
- **basic.lua MinGW**：删除 `C:\msys64` 硬编码；按 `MINGW_PREFIX`、`ProgramData`、`NVIM_MINGW_PATHS` 探测。
- **install.sh**：`is_same_directory` 跳过自部署；WSL 检测日志提示 fnm/tree-sitter-cli。
- **注释**：36 个 `lua/plugins/*.lua` 文件头统一三行格式；`README.md` 维护建议补充模板。
- **文档**：`TROUBLE_SHOOT.md` 增加 Windows 编译工具 / luasnip jsregexp 小节；`PROJECT_MEMORY` #21–#24。

### summary-memory 压缩（2026-06-03 晚）

- **压缩**：28 条 → **25 条**；合并 CRLF/JSONC/env/npm 为 #22；合并路径/无头/Win 安装为 #10–#14。
- **修正**：#14 白名单含 `%USERPROFILE%` health 误报（非可修复项）；packer 备份路径 `nvim-data/backups/`；`NVIM_SKIP_LAZY_UPDATE` 默认 1；`MSYS2_ARG_CONV_EXCL`。
- **删除/并入**：独立 #11–#15 安装排错条目、旧 `w!/redir` 写法、#28 与 #14 矛盾表述。

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

## 2026-06-04

### 跨平台默认代理 + headless fnm 误建 %APPDATA% 修复（summary-memory）

- **代理**：`scripts/common.sh` 统一 `setup_default_proxy`（本机 7890 / WSL 宿主机 IP / 2s 探测 / `USE_PROXY=0`）；`install.sh` 全平台调用；`basic.lua` 第三层自动默认 + `vim.notify`。
- **%APPDATA% 根因**：Git Bash 中 `%APPDATA%` 不展开；`headless_validate.sh` 在仓库根 `eval fnm env` 时若未 export APPDATA，fnm 会创建字面量 `%APPDATA%/fnm`。
- **修复**：`common.sh` 新增 `ensure_windows_appdata_export`、`fnm_env_safe`、`cleanup_stray_appdata_in_dir`；headless 前后清理；`install.sh` 无头结束后再次清理。
- **验收**：`./install.sh` exit 0；安装后仓库根无 `%APPDATA%/`；代理日志正常。

### 文档同步 + 误建目录重测（summary-memory 续）

- **文档**：`README.md`、`TROUBLE_SHOOT.md`、`.cursor/rules/headless-testing.mdc` 代理说明对齐 `setup_default_proxy`（含 WSL 宿主机、`env USE_PROXY=0`）。
- **重测**：`install_retest_appdata.log` 记录 step 7 前仍可能短暂出现 `%APPDATA%`（早期步骤），backup 前/无头后清理后**最终无残留**；单独 `headless_validate.sh` 不再误建。
- **清理**：删除会话测试 log（保留 `docs/nvim_checkhealth_final.log`）。

### 安装更新与健康清零（同日晚间）

- 执行 `./install.sh` → 无头 `Lazy! update` → 无头 `checkhealth`，严格口径全绿。
- 新增规则 [`.cursor/rules/headless-testing.mdc`](../.cursor/rules/headless-testing.mdc)；`nvim-treesitter` 钉在 `master`（0.11 兼容）；证据 `docs/nvim_checkhealth_final.log`。
- 经验摘要已写入 `PROJECT_MEMORY.md`「无头模式经验」小节。

### 分屏 Tab + neo-tree E95（summary-memory）

- **Tab 架构**：`bufferline.nvim` 仅全局 tabline；垂直分屏时标签无法各跟各 window。
- **winbuf.nvim**：每 window 用 winbar 独立 tab（VS Code editor group）；`showtabline=0`；bufferline `enabled=false`；键位见 `ui_buffer_tabpage_winbuf.lua`。
- **bufferline 遗留**：`always_show_bufferline=false`；`custom_filter` 过滤 UI/special buffer；`<leader>b` 关 buffer，`<leader>q` 仅关分屏。
- **neo-tree E95**：`nvim_win_close` toggle 留孤儿 buffer → `execute({ toggle })` + `auto_clean_after_session_restore` + `NEO_TREE_BUFFER_LEAVE`。
- **验收**：`bash scripts/headless_validate.sh` exit 0；`lazy-lock.json` 含 `winbuf.nvim`。

### toggleterm 窗口 resize（summary-memory）

- **现象**：`<leader>/` 打开水平终端后 `Ctrl+Up/Down` 把终端撑满、编辑区压扁，黑屏难恢复。
- **根因**：`window_control` 未识别 `buftype=terminal`；裸 `resize` + `persist_size=true`。
- **修复**：`clamp_terminal_height`（8～55% 行高）；`persist_size=false`；`t`/`n` 模式绑定 Ctrl+方向键；恢复用 `<leader>wr`。

### toggleterm cwd + neo-tree 会话恢复（summary-memory，2026-06-05）

- **终端 cwd（Win Git Bash）**：`<leader>/` 落在 HOME 而非项目目录；根因 login shell + 反斜杠路径 + 未传 `dir`。
- **修复**：`terminal_toggleterm.lua` `terminal_workspace_dir()`、`autochdir`、`on_open` cd；`scripts/bash.cmd` 非 login + `$PWD` 锚定；Linux/macOS/WSL 仅正斜杠 `dir` 逻辑。
- **neo-tree 半恢复**：starter `S` 后左侧空壳 buffer（`neo-tree filesystem [1]` 无树）；`mks` 无法恢复 manager 状态；`Neotree close` 关不掉 session 孤儿窗。
- **修复**：[`lua/config/neo_tree_session.lua`](../lua/config/neo_tree_session.lua) sidecar `*.neo-tree.json`；`purge_neo_tree_artifacts()`；`PersistenceLoadPost` 延迟 rebuild；starter `load_session({ prefer_sidecar=true })`；无头 `persistence.stop()`。
- **环境**：Git Bash 可能加载 msys 与 `Users\.config\nvim` 双副本；`find_our_config_dir` 优先 init.lua 脚本路径。
- **验收**：项目目录开 neo-tree → `<leader>Q` → `nvim` → `S` 左侧完整目录树；`headless_validate.sh` 不覆盖用户 session。
