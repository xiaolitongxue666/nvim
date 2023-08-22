-- jose-elias-alvarez/null-ls.nvim

-- Use Neovim as a language server to inject LSP diagnostics,
-- code actions, and more via Lua.

-- https://github.com/jose-elias-alvarez/null-ls.nvim

-- issue :
-- 1 - This plug no longer support
-- 2 - Blow config on macos when save buffer formatting will show wrong image
--   - Use `:lua vim.lsp.buf.format()` also show wrong image
--   - When use `vim.o.listchars = "space:·"` will show wrong image
--   - Use `vim.o.listchars = 'space:_,tab:>~'` will fix thie issue

return {
    {
        -- Plug name
        "jose-elias-alvarez/null-ls.nvim",
        -- Lazy-load on event
        event = { "BufReadPre", "BufNewFile" },
        -- A list of plugin names or plugin specs that should be loaded when the plugin loads.
        dependencies = { "mason.nvim" },
        -- Config is executed when the plugin loads.
        config = function()
            local null_ls = require("null-ls")
            local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
            null_ls.setup({
                sources = {
                    null_ls.builtins.formatting.stylua,
                    null_ls.builtins.formatting.black,
                },
                on_attach = function(client, bufnr)
                    if client.supports_method("textDocument/formatting") then
                        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
                        vim.api.nvim_create_autocmd("BufWritePre", {
                            group = augroup,
                            buffer = bufnr,
                            callback = function()
                                -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
                                vim.lsp.buf.format({ async = false })
                            end,
                        })
                    end
                end,
            })
        end,
    },
}