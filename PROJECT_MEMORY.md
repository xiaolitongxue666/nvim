# Project Memory (Compact)

> 权威项目记忆文件。`install.sh` 结束时把本文件同步到 `CLAUDE.md`、`AGENTS.md`、`.cursor/rules/project-memory.mdc`。
> 编辑本文件后重跑 `./install.sh` 同步到各 Agent 配置。

## 架构概览

1) **单一来源**：终端 Neovim 以 `lua/basic.lua` 为选项来源，vscode-neovim `require("basic")` 加载再覆盖嵌入层，IdeaVim 手动翻译 IdeaVim 支持的 `set` 子集。

2) **三入口安装**：主 `install.sh`（16 步流水线）→ 终端 nvim；`vscode_neovim/install.sh` → Cursor/VS Code；`ideavimrc/install.sh` → IntelliJ IdeaVim。

3) **环境依赖**：`uv`（Python venv + pynvim/pyright/ruff-lsp/debugpy/black/isort/flake8/mypy）+ `fnm`（Node LTS + neovim npm + tree-sitter-cli + pnpm）。

4) **agent 配置同步**：`install.sh` 第 15 步将 `PROJECT_MEMORY.md` 同步到 `CLAUDE.md`、`AGENTS.md`、`.cursor/rules/project-memory.mdc`。

## 配置应用方式

5) **终端 nvim**：`init.lua` → `require("basic")` → `require("keybindings")` → `require("window_control")` → `require("config.lazy")` → `lua/plugins/*.lua`（按功能拆分的 36 个插件规格文件）。`init.lua` 尾部有 `detect_python_host_from_uv()` / `detect_node_host_from_fnm()` 动态检测路径。

6) **vscode-neovim（Cursor/VS Code）**：`vscode_neovim/vscode_neovim_init.lua` 嵌入初始化 → `require("basic")` 加载基础选项 → 嵌入覆盖（showtabline=0, mouse=""）→ 独立键位经 `VSCodeNotify` 转发到编辑器命令（gd/gD/gr/gI/gy/D/leader cr ca cf），不加载 lua/plugins/lspconfig。

7) **IdeaVim（IntelliJ）**：`ideavimrc/.ideavimrc` 手写复制到 `~/.ideavimrc`；选项与 basic.lua 对齐；Neovim 优先策略（冲突键改前缀：FileStructurePopup → leader fo，PrevSplitter → leader pi）。

## 已知边界与约束

8) **LSP 键位双份维护**：终端 `gd`/`gD`/`gr`/`gI`/`gy`/`D` → `lua/plugins/lsp_server_nvim-lspconfig.lua`；vscode-neovim → `vscode_neovim_init.lua` 的 `VSCodeNotify`；改一处须核对另一处。

9) **跨编辑器选项变更流程**：优先改 `lua/basic.lua` → 核对 vscode 嵌入覆盖（`vscode_neovim_init.lua` 顶部）→ 核对 ideavim `set` 映射表（`.ideavimrc` 第一节）。

10) **Windows 路径（Git Bash）**（2026-06-03）：`scripts/common.sh` 提供 `windows_path_to_unix` / `unix_path_to_windows` / `is_gitbash_absolute_path`；`setup_windows_config_redirect` 须探测含/不含 `XDG_CONFIG_HOME` 的 stdpath 并用 **PowerShell** `New-Item -ItemType Junction` 建联接（Git Bash 下 `cmd mklink` 易挂起或转义错误）。未设 XDG 时 stdpath 可能为 `C:\msys64\home\...\AppData\Local\nvim`（非 `~/.config/nvim`）；`~/.bashrc` 应设 `export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"`。旧 sed `C:`→`c` 缺 `/` 前缀会误建 `~/.config/nvim/c/`。提交前 `settings.json` 不得含本机 `neovimInitVimPaths`。

## 安装排错记录

11) **CRLF 行尾**（2026-06-02）：主 `install.sh` 和 `vscode_neovim/install.sh` 在 Windows Git Bash 上是 CRLF，shebang 行 `#!/usr/bin/env bash^M` 导致 `The system cannot find the path specified`。修复：`sed -i 's/\r$//'`。macOS 侧 `vscode_neovim/install.sh` 也须保持 LF。

12) **JSONC 不兼容**（2026-06-02）：Cursor `settings.json` 开头有 `//` 注释（合法 JSONC），但 `vscode_neovim/install.sh` 的内嵌 Python 合并脚本用 `json.loads()`（标准 JSON）解析，报 `JSONDecodeError`。修复：先用 `sed -i '/^\/\//d'` 去掉注释行再跑脚本。改进建议：合并脚本改用 JSONC 解析库。

13) **neovim npm 包安装失败**（2026-06-02）：`install.sh` 第 10 步 `npm install -g neovim` 失败（网络/registry 原因），导致 `node_host_prog` 未设置。修复：手动 `npm install -g neovim`。Windows 上 `require.resolve('neovim/bin/cli.js')` 不搜索全局 node_modules，需设 `NODE_PATH` 或改 fallback 逻辑。

14) **Windows env var 语法**（2026-06-02）：`VAR=val command` 在 Windows Git Bash 管线下不生效；改用 `env VAR=val command`。

15) **自部署冗余**（2026-06-02）：仓库本身就是 `~/.config/nvim` 时，`install.sh` 的 `deploy_config` 步骤执行 `cp` 全为自身复制（约 18 条 "同一文件" 警告，无害）。建议在检测到 SCRIPT_DIR == NVIM_CONFIG_DIR 时跳过部署。

16) **nvim-treesitter 分支锁定**（2026-05-19）：`Lazy update` 拉到了需 Neovim 0.12+ 的 rewrite 版 `main` 分支；本机 0.11.5 需锁定为上游兼容分支 `master`（`lua/plugins/code_highlight_nvim-treesitter.lua` + `lazy-lock.json`）。

17) **无头模式测试经验**：必须 `-u init.lua`；健康检查用 `-c "checkhealth" -c "w! docs/..."`（`redir` 在 headless 下常只得到标题）；插件未就绪时用 `vim.wait` + `pcall(require, ...)`；验收 grep 用 `^- ERROR|^- WARNING|❌|⚠`（避免误判 treesitter 图例）。

18) **Settings Sync 注意**（2026-05-21）：mac 安装会写入三平台 `neovimInitVimPaths.*`；若同步到 Windows 导致 `win32` 路径错误，在 Windows 重跑 `install.cmd` 或 `install.sh`。

19) **collect_plugin_specs**（2026-06-03）：`lua/config/lazy.lua` 手动 glob 插件规格（不依赖 rtp）。Windows glob 返回反斜杠路径，modname 须用 `^.+[\\/]lua[\\/]`。单条 spec 简写 `{ "plugin/name", config = ... }` 若误判为多 spec（`result[1]` 为 string 时仍应整表插入），会导致 **config 从不执行**（mini.starter 等仅加载默认行为）。

20) **mini.starter 启动页**（2026-06-03）：Neovim 0.11 内置 intro 或空 buffer 可能触发 `is_something_shown()`，跳过 `autoopen`。`basic.lua` 的 `shortmess` 加 `I` 禁用 intro；`greeter_dashboard_mini-starter.lua` 设 `autoopen = false`，在 `UIEnter` 调用 `starter.open()`。

21) **init.lua 路径自愈**（2026-06-03）：`find_our_config_dir` 在 `require("basic")` 前修 `package.path`，在 `require("config.lazy")` 前修 `runtimepath`；`VimEnter` 防 rtp 被重置；`our_config` 用于 venv 路径检测。

# 已修复的历史问题（参考）

- `<Tab>`、`<C-f>/<C-b>`、`<leader>/` 键位重复/冲突已治理
- 保存自动格式化与手动格式化入口已统一走 conform
- Python 侧 `pyright` 与 `ruff_lsp` 重复诊断已修复（2026-05-19）
- `neodev` → `lazydev`、`dressing` → Snacks 替代已落地（2026-05-19）
