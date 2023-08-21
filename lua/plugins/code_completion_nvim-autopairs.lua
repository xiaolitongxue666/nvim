-- windwp/nvim-autopairs

-- Autopairs for neovim written by lua

-- https://github.com/windwp/nvim-autopairs

return {
    {
        -- Plug name
        "windwp/nvim-autopairs",
        -- Lazy-load on event
        event = "VeryLazy",
        -- Config is executed when the plugin loads.
        config = function()
            require("nvim-autopairs").setup({})
        end,
    },
}