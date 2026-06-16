# Neovim Config — Claude Project Context

> Auto-synced from PROJECT_MEMORY.md by install.sh at 2026-06-16T13:55:36Z. Edit PROJECT_MEMORY.md instead.


## 架构概览

1) **单一来源**：终端 Neovim 以 `lua/basic.lua` 为选项来源；vscode-neovim `require("basic")` 再覆盖嵌入层；IdeaVim 手动翻译 `.ideavimrc` 支持的 `set` 子集。

2) **三入口安装**：根 `install.cmd`/`install.sh`（18 步）→ 终端 nvim；`vscode_neovim/install.sh` → Cursor/VS Code；`ideavimrc/install.sh` → IdeaVim。

3) **环境依赖与 install**（18 步）：`install.sh` 自动装/升级 git、uv、fnm、Neovim>=0.11、Python venv（`uv pip -U`）、npm 全局包；`scripts/deps/` 模块化（`manifest.sh` 为清单 SSOT）；**Mason 默认不在 install 预同步**（`NVIM_SKIP_MASON=0` 可选 headless，慢且易失败）；首次 `nvim` 由 `mason-tool-installer`（`run_on_start`）+ `mason-lspconfig`（`automatic_installation`）后台安装；测试 `scripts/tests/test_deps.sh`。

4) **agent 同步**：`install.sh` 第 18 步将本文件同步到 `CLAUDE.md`、`AGENTS.md`、`.cursor/rules/project-memory.mdc`。

5) **终端启动链**：`init.lua` → `basic` → `keybindings` → `window_control` → `config.lazy` → `lua/plugins/*.lua`（36 个规格）；尾部 `detect_python_host_from_uv` / `detect_node_host_from_fnm`。

6) **vscode-neovim**：`vscode_neovim_init.lua` 嵌入 → `require("basic")` → 覆盖 showtabline/mouse → LSP 键经 `VSCodeNotify`（不加载 lspconfig 插件栈）。

7) **IdeaVim**：`.ideavimrc` 对齐 basic.lua；冲突键改前缀（FileStructurePopup→leader fo，PrevSplitter→leader pi）。

8) **LSP 键位双份**：终端 `lua/plugins/lsp_server_nvim-lspconfig.lua`；vscode `vscode_neovim_init.lua`；改一处须核对另一处。

9) **跨编辑器改选项**：先 `basic.lua` → 核对 vscode 嵌入覆盖 → 核对 `.ideavimrc` 第一节。

10) **Windows 路径**：`scripts/common.sh` 路径互转；`setup_windows_config_redirect` 用 PowerShell Junction（勿用 Git Bash mklink）；`~/.bashrc` 设 `XDG_CONFIG_HOME`；提交前 `settings.json` 勿含本机 `neovimInitVimPaths`。

11) **Win 安装 + 跨平台代理**（2026-06-04）：`ensure_windows_user_env`；`setup_default_proxy`（`common.sh`，install/headless 共用；本机 `127.0.0.1:7890`、WSL 宿主机 IP、`PROXY_PROBE_TIMEOUT` 2s 探测不可达跳过、`env USE_PROXY=0`）；`basic.lua` 第三层自动默认；`ensure_windows_appdata_export` + `fnm_env_safe` 防误建 `%APPDATA%`；`cleanup_stray_appdata_in_dir`（backup 前、无头后）；`cleanup_legacy_packer`；说明见 README / TROUBLE_SHOOT / headless-testing.mdc。

12) **无头验收**：`bash scripts/headless_validate.sh`（或保持可执行位）；`install.sh` 末尾默认调用（`NVIM_SKIP_HEADLESS=1` 跳过）；默认 `NVIM_SKIP_LAZY_UPDATE=1`（~20s）；完整同步设 `NVIM_SKIP_LAZY_UPDATE=0`（Lazy+Mason 90s）。

13) **无头 env**：`run_nvim` 设 `MSYS2_ARG_CONV_EXCL=*` 并 export 环境变量；checkhealth 落盘用 `set buftype=` + `write! docs/nvim_checkhealth_final.log`（勿依赖 `redir`/`w!`）。

14) **务实 grep**：fail 于 ERROR/❌ 与 lazy packer 残留；白名单 headless/dumb 的 Slow shell、terminfo、`Missing user config file`（`nvim/init.lua` 或 `%USERPROFILE%`，`-u init.lua` 已加载）、luasnip jsregexp；见 `TROUBLE_SHOOT.md`。

15) **init.lua 路径栈**：`find_our_config_dir` **优先 init.lua 脚本目录**（避免 Git Bash stdpath 指向 msys 旧副本）；再 stdpath/XDG；修 rtp/package.path；`vim.g.nvim_config_dir`；`lua/config/paths.lua` 供 lazy glob/lockfile。

16) **lazy 插件加载**：`collect_plugin_specs` 手动 glob；Windows 反斜杠 modname 用 `^.+[\\/]lua[\\/]`；单条 `{ "name", config=... }` 勿拆成多 spec（否则 config 不执行）。

17) **nvim-treesitter**：Neovim 0.11 锁 `branch=master`（`main` 需 0.12+）；无头须 `-u init.lua` + `vim.wait` 等 treesitter 就绪。

18) **mini.starter**：`shortmess` 加 `I` 禁 intro；`autoopen=false`，`UIEnter` 调 `starter.open()`；会话 `s`/`S` 经 `config.neo_tree_session.load_session`（`S` 优先带 sidecar 的会话）。

19) **Windows MinGW**：`basic.lua` 动态探测 `MINGW_PREFIX`/`ProgramData`/`NVIM_MINGW_PATHS`，仅无 `gcc` 时 prepend PATH。

20) **LuaSnip jsregexp**：Windows 可选 `Lazy build LuaSnip`（需 make/MinGW）；失败仅 WARNING。

21) **WSL**：`/proc/version` 含 Microsoft 时提示 `fnm env` 与 Linux 侧 tree-sitter-cli；代理默认宿主机 `:7890`（`resolve_default_proxy_host`，非 127.0.0.1）。

22) **安装排错合集**：CRLF shebang 用 `sed -i 's/\r$//'`；vscode `install.sh` JSONC 行首 `//` 须剥离；Git Bash 用 `env VAR=val`；Windows npm 或需 `NODE_PATH`；**msys 与 `%USERPROFILE%\.config\nvim` 双副本**时重跑 `install.sh` 或设 `XDG_CONFIG_HOME`。

23) **自部署与 Settings Sync**：仓库即 `~/.config/nvim` 时 `is_same_directory` 跳过 `deploy_config`；mac 写入三平台 `neovimInitVimPaths`；Windows 路径错则重跑 `install.cmd`/`install.sh`。

24) **分屏 Tab + neo-tree toggle**（2026-06-04）：winbar 用 `winbuf.nvim`（`bufferline` `enabled=false`，`showtabline=0`）；`[b`/`]b`/`<leader>b` 关 buffer。neo-tree 勿 `nvim_win_close` toggle（E95）；`<leader>e`/`fe` 用 `execute({ toggle })`；`NEO_TREE_BUFFER_LEAVE` 清孤儿 buffer。

25) **toggleterm cwd + neo-tree 会话**（2026-06-05）：Win Git Bash 仅 `<leader>/` 显式 `dir=getcwd()`（正斜杠）、`autochdir`、`on_open` 带引号 cd、`scripts/bash.cmd` 非 login + `$PWD` 锚定。会话：`lua/config/neo_tree_session.lua` 写 sidecar `*.neo-tree.json`；退出 `PersistenceSavePre` purge 后 `mks`；`PersistenceLoadPost` **purge session 空壳 buffer** 再 `focus`（`Neotree close` 无效）；无头 `NVIM_HEADLESS_VALIDATE=1`→`persistence.stop()`。插件文件头三行注释见 `README.md`。

# 问题 / 解法（install 与 Mason）

| 现象 | 处理 |
|------|------|
| `install.sh` Mason 步骤慢或 `Neovim is exiting while packages are still installing` | 默认 `NVIM_SKIP_MASON=1`（deferred）；首次 `nvim` 自动装；勿在 headless 用 `MasonInstall`+`qa!` 与 tool-installer 竞态 |
| headless 误用 `mason-registry.is_installing()` | 该 API 不存在；若需 install 内预同步用 `scripts/deps/mason_sync.lua` 逐包 `pkg:is_installed()` |
| winget `msstore` 证书错误 | `platform_pkg.sh` 已加 `--source winget`；非致命 |
| `npm install -g neovim` 失败 (Win) | 非致命；`init.lua` 仍可用 venv Python + Ruby gem host |
| `~/.config/nvim.backup.*` 在父目录堆积 | install 步骤 9 备份；可手动删旧备份，保留最近 1～2 份 |

# 已修复的历史问题（参考）

- 键位冲突、conform 统一格式化、pyright/ruff 重复诊断、neodev→lazydev、dressing→Snacks 已治理
- bufferline 全局 tab 无法分屏独立显示 → winbuf.nvim；`<leader>b` 曾误删 alternate buffer 已修正
- neo-tree `<leader>e` E95：`nvim_win_close` 留孤儿 buffer → 原生 toggle + buffer leave 清理
- toggleterm `<leader>/` + `Ctrl+Up/Down` 撑满屏：`window_control` 须识别 `buftype=terminal` 限高；`persist_size=false`；布局乱了 `<leader>wr`（`wincmd =`）
- toggleterm Win cwd 落在 HOME：`terminal_workspace_dir` 正斜杠 + 显式 `dir` + `bash.cmd` 非 login（Git Bash 仅 Windows）
- neo-tree 会话半恢复（空壳 buffer）：sidecar `*.neo-tree.json` + `purge_neo_tree_artifacts` + starter `S` 优先 sidecar；无头不写 session
