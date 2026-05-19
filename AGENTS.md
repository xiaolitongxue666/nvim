# Neovim Config — Agent Instructions

> Auto-synced from PROJECT_MEMORY.md by install.sh at 2026-05-19T08:26:22Z. Edit PROJECT_MEMORY.md instead.


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
