-- mason-lspconfig.nvim

-- Extension to mason.nvim that makes it easier to use lspconfig with mason.nvim.

-- https://github.com/williamboman/mason-lspconfig.nvim
-- https://github.com/williamboman/mason-lspconfig.nvim#available-lsp-servers

return {
    {
        -- Plug name
        "williamboman/mason-lspconfig.nvim",
        -- Config is executed when the plugin loads.
        config = function()
            require("mason").setup()
            require("mason-lspconfig").setup()
        end
    },
}
