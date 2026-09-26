#!/usr/bin/env bash
# 依赖清单（与 lua/plugins 中 Mason ensure_installed 对齐；变更时同步两处）

# Python venv 包：仅 Neovim Python host。LSP/格式化/调试由 Mason 安装。
NVIM_PYTHON_PACKAGES=(
    pynvim
)

# npm 全局包（Neovim node host 与 tree-sitter CLI）
NVIM_NPM_PACKAGES=(
    neovim
    tree-sitter-cli
)

# Mason LSP（lua/plugins/lsp_server_nvim-lspconfig.lua）
NVIM_MASON_LSP_PACKAGES=(
    lua_ls
    bashls
    clangd
    pyright
    rust_analyzer
    jsonls
    yamlls
    marksman
)

# Mason 工具（conform / dap / ruff-lsp；与 lsp_server_manager_mason.lua 对齐）
NVIM_MASON_TOOL_PACKAGES=(
    ruff-lsp
    black
    stylua
    debugpy
    codelldb
)

# 系统工具（scripts/deps/install_system_utils.sh）
NVIM_SYSTEM_PACKAGES=(
    git
    curl
    tar
)

# 搜索工具：neo-tree 使用 fd，spectre 使用 rg。缺失才安装，不升级。
NVIM_SEARCH_TOOLS=(
    fd
    rg
)

# 语言工具：rustup 预编译工具链；C 编译器仅检查系统是否已有 clang/gcc。
NVIM_LANGUAGE_TOOLS=(
    rust
    c_compiler
)

# Neovim 官方 release 版本（须与 script_tool run_once_install-neovim 同步）
readonly NEOVIM_RELEASE_VERSION="v0.11.5"

# 合并 Mason 安装列表（去重顺序保留）
nvim_mason_all_packages() {
    local seen="" pkg result=()
    for pkg in "${NVIM_MASON_LSP_PACKAGES[@]}" "${NVIM_MASON_TOOL_PACKAGES[@]}"; do
        if [[ " ${seen} " != *" ${pkg} "* ]]; then
            result+=("${pkg}")
            seen="${seen} ${pkg}"
        fi
    done
    printf '%s\n' "${result[@]}"
}
