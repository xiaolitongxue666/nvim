-- nvim-telescope/telescope.nvim

-- Find, Filter, Preview, Pick. All lua, all the time.

-- https://github.com/nvim-telescope/telescope.nvim

return {
    {
        -- Plug name
        'nvim-telescope/telescope.nvim', tag = '0.1.2',
        -- or                              , branch = '0.1.x',
        -- A list of plugin names or plugin specs that should be loaded when the plugin loads.
        dependencies = { 'nvim-lua/plenary.nvim' },
        ---- Lazy-load on command
        cmd = "Telescope",
        -- Lazy-load on key mapping
        keys = {
            { "<leader>p", ":Telescope find_files<CR>", desc = "find files" },
            { "<leader>P", ":Telescope live_grep<CR>", desc = "grep file" },
            { "<leader>rs", ":Telescope resume<CR>", desc = "resume" },
            { "<C-q>", ":Telescope oldfiles<CR>", desc = "oldfiles" },
        },
    },
}
