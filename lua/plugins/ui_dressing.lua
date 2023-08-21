-- stevearc/dressing.nvim

-- Neovim plugin to improve the default vim.ui interfaces

-- https://github.com/stevearc/dressing.nvim

return {
    {
        -- Plug name
        "stevearc/dressing.nvim",
        -- When true, the plugin will only be loaded when needed.
        lazy = true,
        -- Init functions are always executed during startup
        init = function()
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.ui.select = function(...)
                require("lazy").load({ plugins = { "dressing.nvim" } })
                return vim.ui.select(...)
            end
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.ui.input = function(...)
                require("lazy").load({ plugins = { "dressing.nvim" } })
                return vim.ui.input(...)
            end
        end,
    },
}