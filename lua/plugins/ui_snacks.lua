-- folke/snacks.nvim
-- 与 opencode.nvim 共用；需优先加载且不懒加载以满足 checkhealth
-- https://github.com/folke/snacks.nvim

return {
    {
        "folke/snacks.nvim",
        event = "VeryLazy",
        priority = 1000,
        opts = {
            input = { enabled = true },
            picker = { enabled = true },
            notifier = { enabled = false },
            image = { enabled = false },
            terminal = {},
        },
        config = function(_, opts)
            local snacks = require("snacks")
            snacks.setup(opts)
        end,
    },
}
