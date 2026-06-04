-- e-sigs/winbuf.nvim
-- 分屏独立 buffer 标签（winbar）；每个编辑器组有自己的 tab 行——Neovim 里对应的是 winbar（每个 window 一条顶栏），不是 tabline。
-- https://github.com/e-sigs/winbuf.nvim

return {
    {
        "e-sigs/winbuf.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        keys = {
            { "<leader>]", function() require("winbuf").cycle(1) end, desc = "下一个缓冲区（当前分屏）" },
            { "<leader>[", function() require("winbuf").cycle(-1) end, desc = "上一个缓冲区（当前分屏）" },
            { "[b", function() require("winbuf").cycle(-1) end, desc = "上一个缓冲区（当前分屏）" },
            { "]b", function() require("winbuf").cycle(1) end, desc = "下一个缓冲区（当前分屏）" },
            {
                "<leader>b",
                function()
                    local buf = vim.api.nvim_get_current_buf()
                    if vim.bo[buf].modified then
                        local choice = vim.fn.confirm("Buffer 未保存，仍关闭？", "&Yes\n&No")
                        if choice ~= 1 then
                            return
                        end
                        require("winbuf").close_buf(buf, true)
                    else
                        require("winbuf").close_buf(buf)
                    end
                end,
                desc = "关闭当前 buffer（当前分屏）",
            },
            { "<A-h>", function() require("winbuf").move_buf("h") end, desc = "移动 buffer 到左侧分屏" },
            { "<A-l>", function() require("winbuf").move_buf("l") end, desc = "移动 buffer 到右侧分屏" },
            { "<A-j>", function() require("winbuf").move_buf("j") end, desc = "移动 buffer 到下方分屏" },
            { "<A-k>", function() require("winbuf").move_buf("k") end, desc = "移动 buffer 到上方分屏" },
        },
        opts = {
            style = "slant",
            hide_single = false,
            show_close_icon = true,
            max_name_length = 18,
            truncate_names = true,
            diagnostics = "nvim_lsp",
            diagnostics_indicator = function(count, level)
                local icon = level:match("error") and " " or " "
                return " " .. icon .. count
            end,
            highlights = {
                active = { fg = "#cdd6f4", bg = "#313244", bold = true },
                active_sep = { fg = "#89b4fa", bg = "#313244" },
                inactive = { fg = "#6c7086", bg = "#1e1e2e" },
                inactive_sep = { fg = "#45475a", bg = "#1e1e2e" },
                active_close = { fg = "#f38ba8", bg = "#313244" },
                inactive_close = { fg = "#6c7086", bg = "#1e1e2e" },
                active_modified = { fg = "#f9e2af", bg = "#313244" },
                inactive_modified = { fg = "#6c7086", bg = "#1e1e2e" },
                active_diag_error = { fg = "#f38ba8", bg = "#313244", bold = true },
                active_diag_warn = { fg = "#f9e2af", bg = "#313244" },
                inactive_diag_error = { fg = "#f38ba8", bg = "#1e1e2e" },
                inactive_diag_warn = { fg = "#f9e2af", bg = "#1e1e2e" },
                fill = { bg = "#1e1e2e" },
                active_underline = { sp = "#89b4fa", underline = true },
            },
        },
    },
}
