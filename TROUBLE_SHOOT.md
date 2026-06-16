# 故障排查记录

本文档记录在 Windows + Git Bash 环境下执行 `install.sh` 时遇到的问题及解决办法；也记录在 Neovim 内使用 Mason 时出现的同类问题及配置内解决办法。

---

## 问题：项目根目录下出现字面量 `%APPDATA%` 文件夹

### 现象

- 在 Neovim 配置仓库根目录（如 `~/.config/nvim` 或 `C:\Users\<用户名>\.config\nvim`）下执行 `./install.sh` 时，会**在项目根目录下出现一个名为字面量 `%APPDATA%` 的文件夹**（即目录名就是百分号+APPDATA+百分号）。
- 脚本日志中可能出现：
  - `Removed stray %APPDATA% directory from repo (startup)`
  - `Removed stray %APPDATA% directory from repo (before backup)`
  - `Removed stray %APPDATA% directory from repo`
  - `Removed stray %APPDATA% directory created by npm`
- 若未清理，部署配置时 `cp` 可能报错：`cp: '.../nvim/%APPDATA%' and '.../nvim/%APPDATA%' are the same file`（同源同目标复制）。

### 环境

- **系统**：Windows 10/11
- **Shell**：Git Bash（MSYS2 或 MINGW 环境）
- **相关工具**：Node.js、npm、fnm（Node 版本管理）

### 原因简述

在 Bash 中，**Windows 环境变量 `%APPDATA%` 不会被自动展开**。若某程序（如 npm、fnm 或 Node）在运行时：

- 读取的配置或默认路径里含有**未展开的** `%APPDATA%` 字符串，且
- 该程序在**当前工作目录（cwd）**下创建以此字符串为名的目录，

就会在**当前目录**下创建一个名为 `%APPDATA%` 的文件夹，而不是在真正的 `C:\Users\<用户>\AppData\Roaming` 下操作。

此外，在 Git Bash 中通过 `npm` 调用时，实际可能执行的是 `npm.cmd`，进而启动 `cmd.exe`。若未在 **cmd 进程内**显式设置已展开的 `APPDATA` 或未在 **cmd 内**将工作目录切到 APPDATA，则 cmd 子进程的 cwd 可能仍是 Git Bash 的当前目录（即项目根），从而在项目根下创建该目录。

### 可能的创建来源（按执行顺序）

| 阶段 | 可能触发创建的操作 |
|------|---------------------|
| 脚本启动后、step 7 前 | 上次运行残留；或 step 4 的 `fnm --version`、step 5 中与 Node 相关的代理/env 等子进程 |
| Step 10 开头（Node.js 环境） | `eval "$(fnm env --use-on-cd)"`、`node --version`、`fnm list` 等，若 cwd 为项目根且 APPDATA 未正确传递 |
| Step 10 中 npm 块 | `npm config set prefix/cache` 在项目根下执行；或 `npm list -g`、`npm install -g` 等，若 npm 在项目根下运行且内部使用未展开的 `%APPDATA%` |

---

## 解决办法（脚本内已实现）

`install.sh` 中采用「**避免在项目根下创建**」+「**多处清理兜底**」的策略。

### 1. 脚本启动时（main 开头）

- **清理**：若存在 `SCRIPT_DIR/%APPDATA%`，则删除并打日志 `Removed stray %APPDATA% directory from repo (startup)`。
- **导出**：调用 `get_windows_appdata` 获取已展开的 APPDATA（如 `C:\Users\...\AppData\Roaming`），并 `export APPDATA`，使后续所有步骤的子进程尽量继承该值。

作用：消除上次残留，并减少 step 1～6 中（如 fnm）在项目根下创建该目录的概率。

### 2. 获取已展开的 APPDATA：`get_windows_appdata`

- 仅当 `PLATFORM=windows` 时有效。
- 取值顺序：
  1. 若环境变量 `APPDATA` 已存在且不含 `%`，直接使用；
  2. 否则用 `cmd.exe //c "echo %APPDATA%"` 取得展开路径；
  3. 若仍无，则用 Node 的 `child_process.execSync('cmd /c echo %APPDATA%')` 取得。
- 返回 **Windows 风格路径（反斜杠）**，便于在 cmd 内使用；脚本内需转为 Unix 风格时再做 `\` → `/` 及盘符转 `/c/` 等处理。

### 3. Step 7 备份前

- 若存在 `SCRIPT_DIR/%APPDATA%`，则删除并打日志 `Removed stray %APPDATA% directory from repo (before backup)`。
- 作用：避免在打印 "Existing configuration detected, creating backup..." 时用户仍看到该目录。

### 4. Step 10 设置 Node.js 环境：进入 npm 块前

- **先 cd 到安全目录再跑 fnm/node**  
  - 在 `eval "$(fnm env ...)"`、`node --version`、`fnm list` 等之前，若为 Windows，则先取 `get_windows_appdata` 得到 APPDATA，转为 Unix 路径后若存在则 `cd` 到该目录；若不可用则 `cd` 到 `$HOME`。  
  - 执行完 fnm/node 检测后，再 `cd` 回进入 step 10 前的目录。  
- 作用：fnm、node 等若在某处创建字面量 `%APPDATA%`，会落在 APPDATA 或 HOME 下，而不是项目根。

### 5. Step 10 中：npm config set

- **不在项目根下直接执行** `npm config set prefix/cache`。  
- 改为在 **cmd 内**先切到已展开的 APPDATA 再执行，例如：  
  `cmd.exe //c "cd /d \"<APPDATA>\" && set APPDATA=<APPDATA> && npm config set prefix \"<APPDATA>/npm\" --location=user && npm config set cache \"<APPDATA>/npm-cache\" --location=user"`  
- 作用：避免 `npm config set` 在项目根下触发创建 `%APPDATA%`。

### 6. Step 10 中：所有 npm 调用（`_npm`）

- Windows 且已取得 `appdata_for_npm` 时，**不直接执行** `npm "$@"`，而是通过 cmd 在**已展开的 APPDATA 目录下**执行 npm，例如：  
  `cmd.exe //c "cd /d \"<APPDATA>\" && set APPDATA=<APPDATA> && npm <参数>"`  
- 参数按需转义后拼入 cmd 字符串，保证 `npm list -g`、`npm install -g`、`npm root -g` 等都在该 cmd 会话中、cwd 为 APPDATA 的情况下运行。
- 作用：确保 npm 及其子进程的 cwd 不是项目根，从根源上避免在项目根下创建 `%APPDATA%`。

### 7. 每次可能产生该目录的 npm 调用后

- 调用 `_npm_cleanup_stray()`：若为 Windows 且存在 `SCRIPT_DIR/%APPDATA%`，则静默删除（不重复打日志）。
- 在 `_npm list -g neovim` / `_npm install -g neovim`、`_npm root -g`、`_npm install -g tree-sitter-cli`、`_npm install -g pnpm` 等之后各执行一次。
- 作用：若仍有遗漏，立即清理，避免残留到后续步骤。

### 8. Step 10 末尾

- 若存在 `SCRIPT_DIR/%APPDATA%`，则删除并打日志 `Removed stray %APPDATA% directory created by npm`。
- 作用：最后一道兜底，并给用户一个明确提示（若曾创建过）。

### 9. Step 8 部署配置（deploy_config）

- 若存在 `NVIM_CONFIG_DIR/%APPDATA%`，先删除再复制，并打日志 `Removed stray %APPDATA% directory from config`。
- 使用 rsync 或 find+cp 时，对目录/文件名增加 `--exclude='%APPDATA%'` 或 `! -name '%APPDATA%'`，避免复制或报错。
- 作用：防止部署阶段因该目录导致 cp 报错或污染目标配置目录。

---

## 手动检查与预防（可选）

若在**未修改的脚本**或**其他脚本**中仍遇到类似问题，可参考以下做法：

1. **执行脚本前先导出 APPDATA（Git Bash）**  
   ```bash
   export APPDATA=$(cmd //c "echo %APPDATA%" | tr -d '\r\n' | sed 's/\\/\//g' | sed 's/^\([A-Za-z]\):/\/\1/')
   ./install.sh
   ```
   注意：上述 `sed` 仅为一种转成 Unix 路径的写法，可按本机环境调整。

2. **检查 npm 配置中是否含字面量 `%APPDATA%`**  
   ```bash
   npm config get prefix
   npm config get cache
   ```  
   若输出中含 `%APPDATA%`，建议改为已展开的绝对路径，例如：  
   ```bash
   npm config set prefix "C:/Users/<用户名>/AppData/Roaming/npm" --location=user
   npm config set cache "C:/Users/<用户名>/AppData/Roaming/npm-cache" --location=user
   ```

3. **检查系统环境变量**  
   在「系统属性 → 环境变量」中查看用户或系统的 `APPDATA`，确认其值为已展开路径（如 `C:\Users\<用户名>\AppData\Roaming`），且没有错误地写成字面量 `%APPDATA%` 或嵌套引用。

---

## 相关脚本位置索引（install.sh）

| 行号区间/关键字 | 作用 |
|-----------------|------|
| `get_windows_appdata` | 获取已展开的 APPDATA 路径 |
| main 开头、start_script 之后 | 启动时清理并 export APPDATA |
| `backup_existing_config` 开头 | 备份前清理项目根下 `%APPDATA%` |
| `setup_nodejs_environment` 开头 | cd 到安全目录再执行 fnm/node，执行完 cd 回 |
| `setup_nodejs_environment` 内「if command -v npm」块 | 删误建目录、npm config set  via cmd、定义 _npm / _npm_cleanup_stray |
| `_npm()` | Windows 下通过 cmd 在 APPDATA 目录执行 npm |
| `deploy_config` | 删除目标下 `%APPDATA%`，rsync/find 排除该名称 |

以上为当前脚本中与「项目根下出现字面量 `%APPDATA%` 目录」相关的完整问题描述与解决办法记录。

---

## 问题：在 Neovim 内使用 Mason 时出现 `%APPDATA%` 文件夹

### 现象

- 从**配置目录**启动 Neovim（如 `cd ~/.config/nvim && nvim`），执行 **:Mason** 打开 Mason 管理界面，按 **U** 更新全部包后，**项目根目录（即配置目录）下再次出现字面量 `%APPDATA%` 文件夹**。
- Mason 中的 LSP 等更新可能已成功，但该目录会被留在 cwd 下。

### 原因简述

- Neovim 启动时其**当前工作目录（cwd）**为启动时所在目录；从配置目录启动则 cwd 即为配置目录。
- **:Mason** 后按 **U** 会触发 Mason 启动**外部进程**（如 npm/Node）执行安装或更新；这些子进程继承 Neovim 的 **cwd** 和**环境变量**。
- 若此时 **APPDATA** 未设置或仍为字面量 `%APPDATA%`（例如从 Git Bash 启动且未在 shell 中导出），子进程可能在**当前目录（配置目录）**下创建名为 `%APPDATA%` 的文件夹，与 install.sh 中「npm 在 cwd 下创建该目录」的根因一致。

### 解决办法（配置内已实现）

1. **启动时为子进程设置 APPDATA（治本）**  
   在 `lua/basic.lua` 中，Windows 下若 `APPDATA` 为空或含 `%`，会通过 `cmd /c "echo %APPDATA%"` 获取已展开路径并设置 `vim.env.APPDATA`。Neovim 及之后通过 Mason 等启动的子进程会继承该环境变量，从源头减少在 cwd 下创建该目录。

2. **进入配置目录时自动清理（兜底）**  
   - **VimEnter** 时：若当前目录为配置目录且存在 `%APPDATA%` 目录，则自动删除并提示「已清理配置目录下的 %APPDATA% 目录」。  
   - **手动清理**：在配置目录下执行 **:NvimConfigCleanAppdata**，可随时删除该目录（仅 Windows 且 cwd 为配置目录时有效）。

3. **可选：启动前导出 APPDATA**  
   若仍偶发创建，可在启动 nvim 前在 shell 中先导出 APPDATA（参见上文「手动检查与预防」），或使用包装脚本在导出后再 `exec nvim`。

### 相关配置位置

| 位置 | 作用 |
|------|------|
| `lua/basic.lua`（Windows 分支） | 启动时设置 `vim.env.APPDATA` 为已展开路径 |
| `lua/basic.lua`（文件末尾） | `clean_appdata_in_config_dir`、VimEnter 自动清理、`:NvimConfigCleanAppdata` 命令 |

### 验证说明

用户确认：在配置目录下执行 :Mason 并按 U 更新后，项目根下不再出现（或明显减少）`%APPDATA%` 目录。若偶发仍出现，可使用 **:NvimConfigCleanAppdata** 手动清理，或下次启动 Neovim 时 VimEnter 会自动清理。

---

## 问题：Windows 编译工具 / LuaSnip jsregexp

### 现象

- `:checkhealth luasnip` 中 **jsregexp** 相关项为 WARNING（Windows 上常见编译失败）。
- Mason 或 treesitter 提示缺少 C 编译器；`:!gcc --version` 在 Neovim 内不可用。

### 原因简述

Neovim 从 Git Bash 启动时，`PATH` 可能不含 MinGW/gcc。本配置在 `lua/basic.lua` 中于 `gcc` 不可用时尝试 prepend 编译工具目录，**不再硬编码** `C:\msys64\...`。

### 探测顺序（basic.lua）

1. `$MINGW_PREFIX/bin`（MSYS2 标准，在 MSYS2 终端或已 export 时生效）
2. `$ProgramData\mingw64\mingw64\bin`
3. 用户自定义 `$NVIM_MINGW_PATHS`（分号分隔，例如 `C:\msys64\mingw64\bin;D:\tools\mingw\bin`）

### 建议操作

1. 安装 [MSYS2](https://www.msys2.org/) 或独立 MinGW-w64，并确保 `gcc` 在系统 PATH 中，或设置 `NVIM_MINGW_PATHS`。
2. 在 Git Bash 启动 Neovim 前可验证：`which gcc` 或 `echo $MINGW_PREFIX`。
3. jsregexp 为 **可选** 加速项；LuaSnip 核心功能不依赖它，WARNING 可忽略。

---

## Win10 → Win11 迁移与统一安装流程

Win10/Win11 共用 `PLATFORM=windows`，不区分版本；推荐同一套入口：

| 步骤 | 命令 |
|------|------|
| 安装/更新 | 仓库根目录 `install.cmd` 或 Git Bash 下 `./install.sh` |
| 无头验收 | `./scripts/headless_validate.sh`（`install.sh` 末尾默认调用；`NVIM_SKIP_HEADLESS=1` 可跳过） |
| 代理 | 默认启用（`scripts/common.sh` 的 `setup_default_proxy`）：本机 `127.0.0.1:7890`；WSL 为宿主机 IP `:7890`（`ip route` / `resolv.conf`）；2s 端口探测不可达则跳过。`env USE_PROXY=0` 关闭；`PROXY_HOST` / `PROXY_PORT` 可覆盖。Neovim 内见 `basic.lua` 第三层自动默认。 |

### packer 残留（lazy checkhealth WARNING）

从 Win10 时代 vim-plug/packer 迁移到 lazy.nvim 后，`%LOCALAPPDATA%\nvim-data\site\pack\packer` 可能仍存在。`install.sh` 的 `cleanup_legacy_packer` 会在 step 12 前备份并删除该目录。

### `%USERPROFILE%` 未展开（vim.health WARNING）

Git Bash / 无头模式下 Neovim 可能仍报告 `Missing user config file: %USERPROFILE%\.config\nvim/init.lua`（即使用 `-u init.lua` 且已设 `XDG_CONFIG_HOME`）。`ensure_windows_user_env` 会将 `USERPROFILE`/`XDG_CONFIG_HOME` 转为正斜杠 Windows 路径；`run_nvim` 设 `MSYS2_ARG_CONV_EXCL=*` 避免 MSYS 改写环境变量。交互式终端一般无此问题。

### vim.provider：Python virtualenv ERROR（Win10 无头）

**现象**：`checkhealth` / 无头验收报 `vim.provider` ❌，`health.lua:93` 与 `python -c "import platform..."`；Python 3 provider 本身（pynvim）可能仍 ✅。

**原因**：Shell 里 `$VIRTUAL_ENV` 指向 `venv/nvim-python`（手动 activate 或 `.bashrc` 自动激活）。Neovim 会额外跑「Python virtualenv」检查，在 Win10 无头 + cmd 子 shell 下裸 `python` 常失败。配置实际用 `g:python3_host_prog`，不依赖 `$VIRTUAL_ENV`。

**处理**（脚本已内置）：`scripts/headless_validate.sh` 的 `run_nvim` 会 `unset VIRTUAL_ENV`。交互式使用前可 `deactivate` 或 `unset VIRTUAL_ENV`。勿用「grep 白名单跳过 ERROR」代替——section 摘要行的 ❌ 会被误计数。

### 无头 checkhealth 卡在 `=== checkhealth ===`

**现象**：`./scripts/headless_validate.sh` 或 `install.sh` 末尾打印 `[INFO] === checkhealth ===` 后长时间无输出（像卡死）。

**常见原因**：

1. **代理不可达**：`setup_default_proxy`（`install.sh` / `headless_validate.sh` 共用）默认本机 `127.0.0.1:7890`，WSL 为宿主机 `:7890`；代理未开时若仍 export 会导致 git/npm 挂起。脚本已 2s 探测端口，不可达则跳过 export。
2. **全量 `checkhealth`**：会跑 snacks、Node provider 的 `npm info` 等联网检查，无头 dumb 终端下可达 75s+ 或挂起。脚本已改为**核心模块**验收 + **90s 超时**。
3. **lazy checker / 缺插件自动安装**：无头启动时 git 拉插件/查更新会挂网络。`NVIM_HEADLESS_VALIDATE=1` 时 lazy 已关闭 checker 与 `install.missing`。

**处理**：

```bash
env USE_PROXY=0 ./scripts/headless_validate.sh
NVIM_CHECKHEALTH_TIMEOUT=180 ./scripts/headless_validate.sh   # 慢网络加大超时
```

交互式完整健康检查仍用 `:checkhealth`（非无头验收）。

### 无头 checkhealth 白名单（务实验收）

以下 WARNING 在 headless + `$TERM=dumb` 下常见，**不计入失败**（见 `scripts/headless_validate.sh`）：

- `vim.health`：`Slow shell invocation`（计时异常）
- `vim.health`：terminfo `key_backspace` / `key_dc` 未找到
- `vim.health`：`Missing user config file: %USERPROFILE%`（无头误报；配置已通过 `-u init.lua` 加载）
- `luasnip`：jsregexp（Windows 无 make 时可选）

可修复项（脚本会 fail）：lazy packer 残留、`packer.backup.*` 目录。

---

## 可选：vscode-neovim / IdeaVim 安装排错

子目录与主 Neovim 配置独立；完整安装步骤见 [vscode_neovim/README.md](vscode_neovim/README.md)、[ideavimrc/README.md](ideavimrc/README.md)。

| 现象 | 处理 |
|------|------|
| Windows 下无法直接运行 `install.sh` | 使用仓库根或子目录 `install.cmd`，或设置 `NVIM_GIT_BASH` 指向 Git Bash 的 `bash.exe` |
| 合并设置后路径仍错误或含 `%APPDATA%` | 复用上文「项目根目录下出现字面量 `%APPDATA%` 文件夹」；[vscode_neovim/install.sh](vscode_neovim/install.sh) 内 `resolve_appdata` 会尝试展开 Windows Roaming 路径 |
| vscode-neovim 扩展找不到 init | 在 `vscode_neovim` 目录重跑 `./install.sh`；编辑器 **Developer: Reload Window**；查看 Output → `vscode-neovim logs` |
| WSL 内 `nvim` + Windows 版 Cursor/VS Code | 需在编辑器设置中配置官方 `vscode-neovim.useWSL` 等，见 [vscode_neovim/README.md](vscode_neovim/README.md)「路径注意」 |
| **`gd` 无法跳转定义** | 嵌入 init **不**加载 `lspconfig`；需 `vscode_neovim_init.lua` 中 `VSCodeNotify` 映射 + 编辑器语言扩展（C/C++ 默认 **clangd**）。重跑 [vscode_neovim/install.sh](vscode_neovim/install.sh)；**Reload Window**；用 F12 验证语言服务；见子 README「LSP 导航键位」 |
| macOS `./install.sh` 报 `env: bash\r` | 脚本 CRLF：在 `vscode_neovim` 目录 `sed -i '' 's/\r$//' install.sh`，或 `bash install.sh` |
| IdeaVim 符号链接失败 | `IDEAVIM_USE_COPY=1 ./install.sh` 强制复制；Windows 符号链接前提见 [ideavimrc/README.md](ideavimrc/README.md)「Windows 符号链接」 |

---

## 依赖安装与升级（scripts/deps/）

`install.sh` 第 4～7、11～12、17 步通过 `scripts/deps/` 自动安装/升级项目依赖。

| 现象 | 处理 |
|------|------|
| WSL 内 `node`/`tree-sitter` 指向 `/mnt/c/...` | 在 WSL 内单独安装 fnm/npm，勿混用 Windows PATH；重跑 `./install.sh` |
| `winget install/upgrade` 失败（无管理员） | 非致命；查看摘要 `Failed/skipped`；手动安装或忽略可选工具 |
| Mason sync 超时 | 默认已跳过 install 预同步；首次 `nvim` 自动装。需 install 内预装：`NVIM_SKIP_MASON=0 ./install.sh` |
| uv/fnm 安装后仍 `command not found` | 将 `~/.local/bin` 加入 PATH 或重新打开终端 |
| Neovim 仍 < 0.11 | 检查 `nvim --version`；Windows 可 `winget upgrade Neovim.Neovim`；Linux 见 script_tool `run_once_install-neovim` 回退 tarball |
| 外网下载失败 | 确认代理 `127.0.0.1:7890`（WSL 用宿主机 IP）；或 `USE_PROXY=0` 后手动配置镜像 |
