-- stevearc/conform.nvim
--
-- 轻量格式化插件，直接对接 LSP textDocument/formatting，与现有 LSP 共存。
-- 内置 stylua、black 等，支持 BufWritePre 保存时格式化。
--
-- https://github.com/stevearc/conform.nvim

return {
    {
        "stevearc/conform.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "black" },
            },
            format_on_save = {
                timeout_ms = 500,
                lsp_format = "fallback",
            },
        },
    },
}
