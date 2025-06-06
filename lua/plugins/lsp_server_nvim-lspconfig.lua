-- neovim/nvim-lspconfig

-- Neovim LSP 快速配置

-- https://github.com/neovim/nvim-lspconfig

return {
    -- 插件名称
    "neovim/nvim-lspconfig",
    -- 插件加载时需要加载的依赖插件列表
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
    },
    -- 插件加载时执行的配置
    -- 所有语言的语法检查和建议配置都在这里
    config = function()
        local lspconfig = require('lspconfig')
        lspconfig.luau_lsp.setup {}
        lspconfig.bashls.setup {}
        lspconfig.clangd.setup {}
        lspconfig.lua_ls.setup {}
        lspconfig.pyright.setup {}
        lspconfig.rust_analyzer.setup {
            -- 服务器特定设置。查看 `:help lspconfig-setup`
            settings = {
                ['rust-analyzer'] = {},
            },
        }
    end,
    -- 按键映射时懒加载
    keys = {
        { "gD", vim.lsp.buf.declaration, desc = "跳转到声明" },
        { "gd", vim.lsp.buf.definition, desc = "跳转到定义" },
    },
}