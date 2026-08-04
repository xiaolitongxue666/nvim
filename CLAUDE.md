# Neovim Config — Claude Project Context

> Auto-synced from PROJECT_MEMORY.md by install.sh at 2026-08-04T05:33:33Z. Edit PROJECT_MEMORY.md instead.

2) **三入口安装**：根 `install.sh`/`install.cmd`（18 步）→ 终端 nvim；`vscode_neovim/install.sh` → Cursor/VS Code；`ideavimrc/install.sh` → IdeaVim。第 18 步把本文件同步到 `CLAUDE.md`、`AGENTS.md`、`.cursor/rules/project-memory.mdc`（编辑本文件后重跑 `install.sh` 同步）。

3) **依赖与 Mason**：install 自动装 git、uv、fnm、Neovim>=0.11、Python venv（`uv pip -U`）、npm 全局包；`scripts/deps/manifest.sh` 为清单 SSOT。Mason 默认不在 install 预同步（`NVIM_SKIP_MASON=1` deferred）；首次 nvim 由 `mason-tool-installer`（run_on_start）+ `mason-lspconfig`（automatic_installation）后台装；LSP 更新统一由 tool-installer 管理（9 server 全部 ensure_installed + auto_update）。勿 headless `MasonInstall`+`qa!` 与 tool-installer 竞态；无 `mason-registry.is_installing()` API，预同步用 `scripts/deps/mason_sync.lua` 逐包 `is_installed()`。

4) **终端启动链**：`init.lua` → `basic` → `keybindings` → `window_control` → `config.lazy` → `lua/plugins/*.lua`；尾部 `detect_python_host_from_uv` / `detect_node_host_from_fnm`。lazy 加载：`collect_plugin_specs` 手动 glob（Windows 反斜杠 modname 用 `^.+[\\/]lua[\\/]`）；单条 `{ "name", config=... }` 勿拆多 spec（否则 config 不执行）。

5) **vscode-neovim + LSP 键位双份**：`vscode_neovim_init.lua` 嵌入 → `require("basic")` → 覆盖 showtabline/mouse → LSP 键经 `VSCodeNotify`（不加载 lspconfig 插件栈）。LSP 键位双份：终端 `lsp_server_nvim-lspconfig.lua` 与 vscode 嵌入文件，改一处须核对另一处。

6) **IdeaVim**：`.ideavimrc` 对齐 basic.lua；冲突键改前缀（FileStructurePopup→leader fo，PrevSplitter→leader pi）。

7) **Windows 路径与 env**：`scripts/common.sh` 路径互转；`setup_windows_config_redirect` 用 PowerShell Junction（勿 Git Bash mklink）；`~/.bashrc` 设 `XDG_CONFIG_HOME`；提交前 `settings.json` 勿含本机 `neovimInitVimPaths`；`ensure_windows_appdata_export` + `fnm_env_safe` 防误建 `%APPDATA%`；`cleanup_stray_appdata_in_dir`（backup 前、无头后）；`cleanup_legacy_packer`。**空 `XDG_CONFIG_HOME=""` 勿 export**（stdpath 退回相对路径 `nvim` 致 vim.health 误报 Missing user config file；脚本已条件导出）。

8) **跨平台代理**（2026-06-04；2026-08-01 更新）：`setup_default_proxy`（common.sh，install/headless 共用）；本机 `127.0.0.1:7890`、WSL 宿主机 IP、**VPS/native 按 `PROXY_PROBE_PORTS`（默认 `7890 17890 7897 10808 1080`）顺序探测，显式 `PROXY_PORT` 只测单端口（对齐 agent-config）**、`PROXY_PROBE_TIMEOUT` 2s 探测不可达跳过、`USE_PROXY=0` 关闭；`basic.lua` 第三层自动默认。

9) **无头验收**：`bash scripts/headless_validate.sh`（install.sh 末尾默认调用，`NVIM_SKIP_HEADLESS=1` 跳过）；默认 `NVIM_SKIP_LAZY_UPDATE=1`（~20s），全量同步设 `NVIM_SKIP_LAZY_UPDATE=0`（Lazy+Mason 90s，约 5min）。`run_nvim` 设 `MSYS2_ARG_CONV_EXCL=*`；checkhealth 落盘用 `set buftype=` + `write! docs/nvim_checkhealth_final.log`（勿依赖 redir/w!）。务实 grep：fail 于 ERROR/❌ 与 packer 残留；白名单 Slow shell、terminfo、`Missing user config file`、luasnip jsregexp；见 `TROUBLE_SHOOT.md`。

10) **init.lua 路径栈**：`find_our_config_dir` **优先 init.lua 脚本目录**（避免 Git Bash stdpath 指向 msys 旧副本）；再 stdpath/XDG；修 rtp/package.path；`vim.g.nvim_config_dir`；`lua/config/paths.lua` 供 lazy glob/lockfile。

11) **nvim-treesitter**：Neovim 0.11 锁 `branch=master`（`main` 需 0.12+）；无头须 `-u init.lua` + `vim.wait` 等就绪。上游 2026-07 `feat(ALL)!: stop support Neovim 0.9`（须 >=0.10；本仓钉 >=0.11，无影响）。

12) **mini.starter + mini.icons**：`shortmess` 加 `I` 禁 intro；`autoopen=false`，`UIEnter` 调 `starter.open()`；会话 `s`/`S` 经 `config.neo_tree_session.load_session`（`S` 优先带 sidecar）。

13) **Windows MinGW + LuaSnip jsregexp**：`basic.lua` 动态探测 `MINGW_PREFIX`/`ProgramData`/`NVIM_MINGW_PATHS`，仅无 `gcc` 时 prepend PATH。jsregexp：Windows 可选 `Lazy build LuaSnip`（需 make/MinGW），失败仅 WARNING；幂等检测避免 WSL/Linux 无头 build 后 SIGSEGV core dump。

14) **WSL**：`/proc/version` 含 Microsoft 时提示 `fnm env` 与 Linux 侧 tree-sitter-cli；代理默认宿主机 `:7890`（`resolve_default_proxy_host` 先 resolv.conf 后 ip route，mirrored 网络回落 127.0.0.1）。

15) **安装排错合集**：CRLF shebang 用 `sed -i 's/\r$//'`；vscode `install.sh` JSONC 行首 `//` 须剥离；Git Bash 用 `env VAR=val`；Windows npm 或需 `NODE_PATH`；**msys 与 `%USERPROFILE%\.config\nvim` 双副本**时重跑 `install.sh` 或设 `XDG_CONFIG_HOME`；winget `msstore` 证书错误已加 `--source winget`（非致命）；`npm -g neovim` 失败非致命（venv Python host）；`~/.config/nvim.backup.*` 堆积可手动删，留 1～2 份。

16) **自部署与 Settings Sync**：仓库即 `~/.config/nvim` 时 `is_same_directory` 跳过 `deploy_config`；mac 写三平台 `neovimInitVimPaths`；Windows 路径错重跑 `install.cmd`/`install.sh`。

17) **分屏 Tab + neo-tree toggle**（2026-06-04）：winbar 用 `winbuf.nvim`（bufferline `enabled=false`，`showtabline=0`）；`[b`/`]b`/`<leader>b` 关 buffer。neo-tree 勿 `nvim_win_close` toggle（E95）；`<leader>e`/`fe` 用 `execute({ toggle })`；`NEO_TREE_BUFFER_LEAVE` 清孤儿 buffer。

18) **toggleterm cwd + neo-tree 会话**（2026-06-05）：Win Git Bash 仅 `<leader>/` 显式 `dir=getcwd()`（正斜杠）、`autochdir`、`on_open` 带引号 cd、`scripts/bash.cmd` 非 login + `$PWD` 锚定；`window_control` 识别 `buftype=terminal` 限高；`persist_size=false`；布局乱用 `<leader>wb`（`wincmd =`；2026-08-01 起 `<leader>wr` 让位 LSP 移除工作区文件夹，勿再用）。会话：sidecar `*.neo-tree.json`；`PersistenceSavePre` purge 后 `mks`；`PersistenceLoadPost` purge 空壳 buffer 再 focus（`Neotree close` 无效）；无头 `NVIM_HEADLESS_VALIDATE=1`→`persistence.stop()`。插件文件头三行注释见 `README.md`。

19) **CodeGraph 代码索引**（2026-08-01）：`codegraph init` 建 `.codegraph/`（SQLite 本地索引）；增量 `codegraph sync`、全量 `codegraph index`、查询 `codegraph query|node <符号>`。`.codegraph/` 在根 `.gitignore` 整体忽略（内层 .gitignore 只忽略内容不忽略自身，须根级条目）。

20) **picker 统一 snacks + 插件瘦身**（2026-08-01）：telescope/fzf-native/bufferline 移除，主 picker 为 `snacks.picker`（键位不变 `<leader>f*/g*/l*`；聚合源 `picker.pick("源名")`，lsp workspace `pick("lsp_symbols",{workspace=true})`；filetype `snacks_picker_input/list`，hardtime 据此放行）。`Comment.nvim`（2024-06 停更）→ `mini.comment`（gcc/gc/gbc 兼容）。snacks 无 vim_options/planets，`<leader>fv/fp` 已移除。

21) **git 更新与全量验证**（2026-08-01）：pull `6e0b4a7` 后 `ui_notice.lua`→`ui_noice.lua`（nvim-noice）；`NVIM_SKIP_LAZY_UPDATE=0 bash scripts/headless_validate.sh` 全量同步（Lazy update + Mason + LuaSnip jsregexp + checkhealth，约 5min）通过。lazy-lock 移除 `mini.comment` 条目属正常——comment.lua 仍引用该插件，Lazy 按需自动重装（实测 `mini.comment OK`）。`.gitignore` 新增本机忽略：`.wslconfig`、`scripts/probe_login.ps1`（内网设备凭据探测脚本，敏感勿入库）。

22) **VIMRUNTIME 完整性检测**（2026-08-04）：WSL apt 安装中断（`neovim` 状态 `iU`、`neovim-runtime` 未装）时 `nvim --version` 正常但启动报 E5113 `vim.uri`/`E484 syntax.vim`/`E5009 Invalid $VIMRUNTIME`。`scripts/common.sh` 新增 `nvim_runtime_probe`（`-u NONE` 查 `$VIMRUNTIME/syntax/syntax.vim`，不加载用户配置）、`nvim_runtime_path`、`verify_nvim_runtime`（分平台修复指引）；install.sh verify 阶段、headless_validate.sh 开头（fail-fast）、install_neovim.sh（apt 分支自动 `sudo apt-get install -f`）均接入；test_deps.sh 含 probe 测试。修复：`sudo apt-get install -f`。见 `TROUBLE_SHOOT.md`。
