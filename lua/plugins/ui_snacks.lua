-- folke/snacks.nvim
-- 与 opencode.nvim 共用；需优先加载且不懒加载以满足 checkhealth
-- https://github.com/folke/snacks.nvim

return {
    {
        "folke/snacks.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            input = {},
            picker = {},
            terminal = {},
        },
    },
}
