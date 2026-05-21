# 仓库清单（当前基线）

生成日期：2026-05-21

## 文档

| 路径 | 用途 | 处置 |
|------|------|------|
| `README.md` | 总览、安装、插件状态、冲突、维护建议 | 保留 |
| `PROJECT_MEMORY.md` | 项目记忆（install.sh 同步到 Agent 配置） | 保留 |
| `CLAUDE.md` / `AGENTS.md` | install.sh 从 PROJECT_MEMORY 生成的 Agent 入口 | 保留（自动生成） |
| `TROUBLE_SHOOT.md` | Windows / Mason / install.sh 排错 | 保留 |
| `docs/LSP_VIEW_AND_MANAGE.md` | LSP / Mason 操作 | 保留 |
| `docs/PROJECT_MEMORY_LOG.md` | 按日期追加的项目记忆日志 | 保留 |
| `docs/plugin_github_audit.txt` | 当前启用插件 GitHub 状态核查原始数据 | 保留 |
| `ideavimrc/README.md` | IdeaVim 子项目 | 保留（独立） |
| `vscode_neovim/README.md` | vscode-neovim / Cursor 子项目 | 保留（独立） |

## 脚本

| 路径 | 引用方 | 处置 |
|------|--------|------|
| `install.sh` | README、TROUBLE_SHOOT、PROJECT_MEMORY 同步 | 保留；合并 `run_with_timeout` |
| `scripts/common.sh` | install.sh | 保留；增加 `run_with_timeout` |
| `scripts/bash.cmd` | toggleterm（Windows） | 保留；改为可配置路径 |
| `scripts/audit_plugins.sh` | 维护用 | 保留 |
| `ideavimrc/install.sh` | ideavimrc | 保留 |
| `ideavimrc/install.cmd` | ideavimrc（Windows） | 保留 |
| `vscode_neovim/install.sh` | vscode_neovim | 保留 |
| `vscode_neovim/install.cmd` | vscode_neovim（Windows） | 保留 |

## 可选目录

| 路径 | 说明 | 处置 |
|------|------|------|
| `test_dir/` | 手动测试样例；install 部署排除 | 保留 |
| `vscode_neovim/` | vscode-neovim：init（含 `VSCodeNotify` LSP 键位）、settings 模板、`install.sh`（vscode-neovim + 默认 clangd）/`install.cmd` | 保留 |
| `.cursor/rules/vscode-neovim.mdc` | Agent：嵌入 Neovim / LSP 键位双份维护约束 | 保留 |
| `ideavimrc/.ideavimrc` | IdeaVim 用户配置源（与 `basic.lua` / 键位策略对齐） | 保留 |

## 插件规格

- 管理器：`lua/config/lazy.lua` + `lua/plugins/*.lua`（36 个文件）
- 去重 GitHub 仓库：54（见 `docs/plugin_github_audit.txt`）
- `lazy-lock.json`：55 条（缺 `schemastore.nvim` 时需 `:Lazy sync`）

## 已删除 / 不再引用的项

- `scripts/common/utils/nvim_checkhealth_to_log.sh`（从未存在）
- README 中的 `none-ls` / `lsp_server_null-ls.lua` 描述
- `HEALTH_CHECK_ANALYSIS.md`（.gitignore 悬空规则已移除）
- `lua/plugins/ui_dressing.lua`（已由 `snacks.nvim` 的 input/picker 替代）

## 生成产物

- `graphify-out/`：graphify 生成目录，已加入 `.gitignore`，默认不纳入版本管理。
