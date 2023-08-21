-- nvim-pack/nvim-spectre

-- Find the enemy and replace them with dark power

-- https://github.com/nvim-pack/nvim-spectre

return {
    {
        -- Plug name
        "nvim-pack/nvim-spectre",
        -- Lazy-load on command
        cmd = "Spectre",
        -- Opts is a table will be passed to the Plugin.config() function. Setting this value will imply Plugin.config()
        opts = { open_cmd = "noswapfile vnew" },
        -- Lazy-load on key mapping
        keys = {
            { "<leader>sr", function() require("spectre").open() end, desc = "Replace in files (Spectre)" },
        },
        -- Config is executed when the plugin loads.
        config = function()
            require("spectre").setup()
        end
    },
}