-- jose-elias-alvarez/null-ls.nvim

-- 使用 Neovim 作为语言服务器来注入 LSP 诊断、
-- 代码操作等，通过 Lua 实现

-- https://github.com/jose-elias-alvarez/null-ls.nvim

-- 问题：
-- 1 - 此插件不再支持
-- 2 - 在 macOS 上保存缓冲区格式化时会显示错误图像
--   - 使用 `:lua vim.lsp.buf.format()` 也会显示错误图像
--   - 当使用 `vim.o.listchars = "space:·"` 时会显示错误图像
--   - 使用 `vim.o.listchars = 'space:_,tab:>~'` 可以修复此问题

return {
    {
        -- 插件名称
        "jose-elias-alvarez/null-ls.nvim",
        -- 在事件时懒加载
        event = { "BufReadPre", "BufNewFile" },
        -- 插件加载时应加载的插件名称或插件规范列表
        dependencies = { "mason.nvim" },
        -- 插件加载时执行配置
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
                                -- 在 0.8 版本中，你应该使用 vim.lsp.buf.format({ bufnr = bufnr }) 代替
                                vim.lsp.buf.format({ async = false })
                            end,
                        })
                    end
                end,
            })
        end,
    },
}