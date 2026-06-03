# Neovim Config — Agent Instructions

> Auto-synced from PROJECT_MEMORY.md by install.sh at 2026-06-03T14:20:27Z. Edit PROJECT_MEMORY.md instead.


## 架构概览

1) **单一来源**：终端 Neovim 以 `lua/basic.lua` 为选项来源；vscode-neovim `require("basic")` 再覆盖嵌入层；IdeaVim 手动翻译 `.ideavimrc` 支持的 `set` 子集。

2) **三入口安装**：根 `install.cmd`/`install.sh`（16 步）→ 终端 nvim；`vscode_neovim/install.sh` → Cursor/VS Code；`ideavimrc/install.sh` → IdeaVim。

3) **环境依赖**：`uv`（Python venv + LSP/formatter 工具链）+ `fnm`（Node LTS + neovim npm + tree-sitter-cli + pnpm）。

4) **agent 同步**：`install.sh` 第 15 步将本文件同步到 `CLAUDE.md`、`AGENTS.md`、`.cursor/rules/project-memory.mdc`。

5) **终端启动链**：`init.lua` → `basic` → `keybindings` → `window_control` → `config.lazy` → `lua/plugins/*.lua`（36 个规格）；尾部 `detect_python_host_from_uv` / `detect_node_host_from_fnm`。

6) **vscode-neovim**：`vscode_neovim_init.lua` 嵌入 → `require("basic")` → 覆盖 showtabline/mouse → LSP 键经 `VSCodeNotify`（不加载 lspconfig 插件栈）。

7) **IdeaVim**：`.ideavimrc` 对齐 basic.lua；冲突键改前缀（FileStructurePopup→leader fo，PrevSplitter→leader pi）。

8) **LSP 键位双份**：终端 `lua/plugins/lsp_server_nvim-lspconfig.lua`；vscode `vscode_neovim_init.lua`；改一处须核对另一处。

9) **跨编辑器改选项**：先 `basic.lua` → 核对 vscode 嵌入覆盖 → 核对 `.ideavimrc` 第一节。

10) **Windows 路径**：`scripts/common.sh` 路径互转；`setup_windows_config_redirect` 用 PowerShell Junction（勿用 Git Bash mklink）；`~/.bashrc` 设 `XDG_CONFIG_HOME`；提交前 `settings.json` 勿含本机 `neovimInitVimPaths`。

11) **Win 安装增强**（2026-06-03）：`ensure_windows_user_env`（USERPROFILE/LOCALAPPDATA/XDG 正斜杠）；`setup_windows_proxy` 默认 7890；`cleanup_legacy_packer` 备份至 `nvim-data/backups/` 并迁出 `site/pack/packer*`。

12) **无头验收**：`bash scripts/headless_validate.sh`（或保持可执行位）；`install.sh` 末尾默认调用（`NVIM_SKIP_HEADLESS=1` 跳过）；默认 `NVIM_SKIP_LAZY_UPDATE=1`（~20s）；完整同步设 `NVIM_SKIP_LAZY_UPDATE=0`（Lazy+Mason 90s）。

13) **无头 env**：`run_nvim` 设 `MSYS2_ARG_CONV_EXCL=*` 并 export 环境变量；checkhealth 落盘用 `set buftype=` + `write! docs/nvim_checkhealth_final.log`（勿依赖 `redir`/`w!`）。

14) **务实 grep**：fail 于 ERROR/❌ 与 lazy packer 残留；白名单 headless/dumb 的 Slow shell、terminfo、`Missing user config file`（`nvim/init.lua` 或 `%USERPROFILE%`，`-u init.lua` 已加载）、luasnip jsregexp；见 `TROUBLE_SHOOT.md`。

15) **init.lua 路径栈**：`find_our_config_dir` 在 require 前修 rtp/package.path；`vim.g.nvim_config_dir`；`vim.fs.joinpath or vim.fs.join`（0.12）；`lua/config/paths.lua` 供 lazy glob/lockfile。

16) **lazy 插件加载**：`collect_plugin_specs` 手动 glob；Windows 反斜杠 modname 用 `^.+[\\/]lua[\\/]`；单条 `{ "name", config=... }` 勿拆成多 spec（否则 config 不执行）。

17) **nvim-treesitter**：Neovim 0.11 锁 `branch=master`（`main` 需 0.12+）；无头须 `-u init.lua` + `vim.wait` 等 treesitter 就绪。

18) **mini.starter**：`shortmess` 加 `I` 禁 intro；`autoopen=false`，`UIEnter` 调 `starter.open()`。

19) **Windows MinGW**：`basic.lua` 动态探测 `MINGW_PREFIX`/`ProgramData`/`NVIM_MINGW_PATHS`，仅无 `gcc` 时 prepend PATH。

20) **LuaSnip jsregexp**：Windows 可选 `Lazy build LuaSnip`（需 make/MinGW）；失败仅 WARNING。

21) **WSL**：`/proc/version` 含 Microsoft 时提示 `fnm env` 与 Linux 侧 tree-sitter-cli。

22) **安装排错合集**：CRLF shebang 用 `sed -i 's/\r$//'`；vscode `install.sh` JSONC 行首 `//` 须剥离或 JSONC 解析；Git Bash 用 `env VAR=val` 非前缀赋值；Windows npm host 或需 `NODE_PATH`。

23) **自部署**：仓库即 `~/.config/nvim` 时 `is_same_directory` 跳过 `deploy_config`。

24) **Settings Sync**：mac 写入三平台 `neovimInitVimPaths`；Windows 路径错则重跑 `install.cmd`/`install.sh`。

25) **插件注释**：`lua/plugins/*.lua` 文件头三行（repo、中文说明、URL）；见 `README.md`。

# 已修复的历史问题（参考）

- 键位冲突、conform 统一格式化、pyright/ruff 重复诊断、neodev→lazydev、dressing→Snacks 已治理
