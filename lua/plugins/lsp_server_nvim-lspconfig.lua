return {
    "neovim/nvim-lspconfig",
    config = function()
        local lspconfig = require('lspconfig')
        lspconfig.clangd.setup {}
        lspconfig.rust_analyzer.setup {
            -- Server-specific settings. See `:help lspconfig-setup`
            settings = {
                ['rust-analyzer'] = {},
            },
        }
    end,
    keys = {
        { "gD", vim.lsp.buf.declaration, desc = "go declaration" },
        { "gd", vim.lsp.buf.definition, desc = "go definition" },
    },
}