-- folke/which-key.nvim

-- Displays a popup with possible keybindings of the command you started typing

-- https://github.com/folke/which-key.nvim

return {
    {
        -- Plug name
        "folke/which-key.nvim",
        -- Lazy-load on event
        event = "VeryLazy",
        -- Init functions are always executed during startup
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
        end,
        -- Opts is a table will be passed to the Plugin.config() function. Setting this value will imply Plugin.config()
        opts = {
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
        }
    },
}