-- nvimtools/none-ls.nvim

-- 使用 Neovim 作为语言服务器来注入 LSP 诊断、
-- 代码操作等，通过 Lua 实现
-- none-ls 是 null-ls 的社区维护版本

-- https://github.com/nvimtools/none-ls.nvim

-- 说明：
-- 1 - 原始的 null-ls 插件已被归档，none-ls 是其社区维护的替代版本
-- 2 - API 保持与 null-ls 完全兼容，无需修改现有配置
-- 3 - 在 macOS 上保存缓冲区格式化时可能显示错误图像
--   - 使用 `:lua vim.lsp.buf.format()` 也会显示错误图像
--   - 当使用 `vim.o.listchars = "space:·"` 时会显示错误图像
--   - 使用 `vim.o.listchars = 'space:_,tab:>~'` 可以修复此问题

return {
    {
        -- 插件名称 (none-ls 是 null-ls 的社区维护版本)
        "nvimtools/none-ls.nvim",
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