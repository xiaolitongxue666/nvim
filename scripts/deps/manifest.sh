#!/usr/bin/env bash
# 依赖清单（与 lua/plugins 中 Mason ensure_installed 对齐；变更时同步两处）

# Python venv 包（install.sh setup_python_environment）
NVIM_PYTHON_PACKAGES=(
    pynvim
    pyright
    ruff-lsp
    debugpy
    black
    isort
    flake8
    mypy
)

# npm 全局包（install.sh setup_nodejs_environment）
NVIM_NPM_PACKAGES=(
    neovim
    tree-sitter-cli
    pnpm
)

# Mason LSP（lua/plugins/lsp_server_manager_mason-lspconfig.lua）
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

# Mason 工具（lua/plugins/lsp_server_manager_mason.lua）
NVIM_MASON_TOOL_PACKAGES=(
    pyright
    ruff-lsp
    black
    isort
    debugpy
    mypy
    taplo
    stylua
    shfmt
    codelldb
)

# 系统工具（scripts/deps/install_system_utils.sh）
NVIM_SYSTEM_PACKAGES=(
    git
    curl
    tar
)

# 语言工具逻辑名（install_language_tools）
NVIM_LANGUAGE_TOOLS=(
    go
    ruby
    composer
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
