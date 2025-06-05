-- lukas-reineke/indent-blankline.nvim

-- Indent guides for Neovim

-- https://github.com/lukas-reineke/indent-blankline.nvim

return {
    {
        -- Plug name
        "lukas-reineke/indent-blankline.nvim",
        -- Main entry point for version 3
        main = "ibl",
        -- Lazy-load on event
        event = { "BufReadPost", "BufNewFile" },
        -- Opts is a table will be passed to the Plugin.config() function. Setting this value will imply Plugin.config()
        opts = {
            indent = {
                char = "│",
            },
            exclude = {
                filetypes = {
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
            },
            scope = {
                enabled = false,
            },
        },
    },
}