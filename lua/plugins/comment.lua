-- numToStr/Comment.nvim

-- Smart and powerful comment plugin for neovim.

-- https://github.com/numToStr/Comment.nvim

return {
    {
        -- Plug name
        "numToStr/Comment.nvim",
        -- Opts is a table will be passed to the Plugin.config() function. Setting this value will imply Plugin.config()
        opts = {
            -- add any options here
        },
        -- When true, the plugin will only be loaded when needed.
        lazy = false,
        -- Config is executed when the plugin loads.
        config = function()
            require("Comment").setup()
            -- Default key map
            -- https://github.com/numToStr/Comment.nvim#configuration-optional
        end
    },
}