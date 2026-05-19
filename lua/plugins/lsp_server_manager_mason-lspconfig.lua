-- mason-org/mason-lspconfig.nvim

-- mason.nvim 的扩展插件，简化 LSP 服务器的安装和配置
-- 提供 mason.nvim 与 nvim-lspconfig 之间的桥梁

-- https://github.com/mason-org/mason-lspconfig.nvim
-- https://github.com/mason-org/mason-lspconfig.nvim#available-lsp-servers

return {
    {
        -- 插件名称
        "mason-org/mason-lspconfig.nvim",
        -- 依赖项：确保 mason.nvim 和 nvim-lspconfig 首先加载
        dependencies = {
            "mason-org/mason.nvim",
            "neovim/nvim-lspconfig"
        },
        -- 在 VeryLazy 事件时加载
        event = "VeryLazy",
        -- 插件配置选项
        opts = {
            -- 自动安装的 LSP 服务器列表
            -- 注意：只包含 mason-lspconfig 支持的服务器名称
            -- ruff_lsp 需要通过 mason.nvim 单独安装，然后在 lspconfig 中配置
            ensure_installed = {
                "lua_ls",           -- Lua 语言服务器
                "bashls",           -- Bash 语言服务器
                "clangd",           -- C/C++ 语言服务器
                "pyright",          -- Python 语言服务器
                "rust_analyzer",    -- Rust 语言服务器
                "jsonls",           -- JSON 语言服务器
                "yamlls",           -- YAML 语言服务器
                "marksman",         -- Markdown 语言服务器
            },
            -- 自动安装缺失的 LSP 服务器
            automatic_installation = true,
            -- 处理程序配置（使用新 API）
            -- lsp 启用与 on_attach 由 lsp_server_nvim-lspconfig.lua 统一处理
            handlers = {
                function() end,
            },
        },
    },
}
