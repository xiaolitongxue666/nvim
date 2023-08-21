-- lukas-reineke/indent-blankline.nvim

-- Indent guides for Neovim

-- https://github.com/lukas-reineke/indent-blankline.nvim

return {
    {
        -- Plug name
        "lukas-reineke/indent-blankline.nvim",
        -- Lazy-load on event
        event = { "BufReadPost", "BufNewFile" },
        -- Opts is a table will be passed to the Plugin.config() function. Setting this value will imply Plugin.config()
        opts = {
            -- char = "▏",
            char = "│",
            filetype_exclude = {
                "help",
                "alpha",
                "dashboard",
                "neo-tree",
                "Trouble",
                "lazy",
                "mason",
                "notify",
                "toggleterm",
                "lazyterm",
            },
            show_trailing_blankline_indent = false,
            show_current_context = false,
        },
    },
}