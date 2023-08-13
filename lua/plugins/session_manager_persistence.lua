return {
    {
        "folke/persistence.nvim",
        event = "BufReadPre", -- this will only start session saving when an actual file was opened
        config = function()
            require("persistence").setup()
        end,
        opts = { options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" } },
        -- stylua: ignore
        keys = {
            { "<leader>ws", function() require("persistence").load() end, desc = "Restore Session" },
            { "<leader>wl", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
            { "<leader>wd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
        },
    },
}
