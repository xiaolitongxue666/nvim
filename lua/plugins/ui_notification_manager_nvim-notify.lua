-- rcarriga/nvim-notify

-- A fancy, configurable, notification manager for NeoVim

-- https://github.com/rcarriga/nvim-notify

return {
    {
        -- Plug name
        "rcarriga/nvim-notify",
        -- Lazy-load on key mapping
        keys = {
            {
                "<leader>un",
                function()
                    require("notify").dismiss({ silent = true, pending = true })
                end,
                desc = "Dismiss all Notifications",
            },
        },
        -- Opts is a table will be passed to the Plugin.config() function. Setting this value will imply Plugin.config()
        opts = {
            timeout = 3000,
            max_height = function()
                return math.floor(vim.o.lines * 0.75)
            end,
            max_width = function()
                return math.floor(vim.o.columns * 0.75)
            end,
        },
        -- Init functions are always executed during startup
        init = function()
            vim.notify = require("notify")
        end,
    },
}