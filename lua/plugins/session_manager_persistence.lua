-- folke/persistence.nvim

-- Simple session management for Neovim

-- https://github.com/folke/persistence.nvim

return {
    {
        -- Plug name
        "folke/persistence.nvim",
        -- Config is executed when the plugin loads.
        event = "BufReadPre", -- this will only start session saving when an actual file was opened
        -- Config is executed when the plugin loads.
        config = function()
            require("persistence").setup()
        end,
        -- Opts is a table will be passed to the Plugin.config() function. Setting this value will imply Plugin.config()
        opts = { options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" } },
        -- Lazy-load on key mapping
        keys = {
            -- Restore Session
            { "<leader>ws", function() require("persistence").load() end, desc = "Restore Session" },
            -- Restore Last Session
            { "<leader>wl", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
            -- Don't Save Current Session
            { "<leader>wd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
        },
    },
}
