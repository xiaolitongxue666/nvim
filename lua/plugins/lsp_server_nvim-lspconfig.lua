-- neovim/nvim-lspconfig

-- Quickstart configs for Nvim LSP

-- https://github.com/neovim/nvim-lspconfig

return {
    -- Plug name
    "neovim/nvim-lspconfig",
    -- A list of plugin names or plugin specs that should be loaded when the plugin loads.
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
    },
    -- Config is executed when the plugin loads.
    config = function()
        local lspconfig = require('lspconfig')
        lspconfig.luau_lsp.setup {}
        lspconfig.bashls.setup {}
        lspconfig.clangd.setup {}
        lspconfig.lua_ls.setup {}
        lspconfig.pyright.setup {}
        lspconfig.rust_analyzer.setup {
            -- Server-specific settings. See `:help lspconfig-setup`
            settings = {
                ['rust-analyzer'] = {},
            },
        }
    end,
    -- Lazy-load on key mapping
    keys = {
        { "gD", vim.lsp.buf.declaration, desc = "go declaration" },
        { "gd", vim.lsp.buf.definition, desc = "go definition" },
    },
}