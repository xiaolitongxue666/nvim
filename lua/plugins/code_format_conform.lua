-- stevearc/conform.nvim
-- 轻量格式化，对接 LSP formatting，支持保存时格式化
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
