-- telescope
-- https://github.com/nvim-telescope/telescope.nvim

return {
    {
        -- Plug name
        'nvim-telescope/telescope.nvim', tag = "0.1.5", -- 或者                              , branch = '0.1.x',
        -- A list of plugin names or plugin specs that should be loaded when the plugin loads.
        dependencies = { 'nvim-lua/plenary.nvim' },
        cmd = "Telescope", -- 在命令时懒加载
        -- Lazy-load on key mapping
        keys = {
            { "<leader>p", ":Telescope find_files<CR>", desc = "find files" },
            { "<leader>P", ":Telescope live_grep<CR>", desc = "grep file" },
            { "<leader>rs", ":Telescope resume<CR>", desc = "resume" },
            { "<C-q>", ":Telescope oldfiles<CR>", desc = "oldfiles" },
        },
    },
}
