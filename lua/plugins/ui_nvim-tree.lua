-- nvim-tree/nvim-tree.lua

-- A file explorer tree for neovim written in lua

-- https://github.com/nvim-tree/nvim-tree.lua

return {
    {
        -- Plug name
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        -- Lazy-load on command
        cmd = "NvimTreeToggle",
        -- Lazy-load on key mapping
        keys = {
            { "tt", ":NvimTreeToggle<CR>", desc = "Toggle NvimTree" },
        },
        config = function()
            require("nvim-tree").setup({
                filters = {
                    dotfiles = true,
                },
            })
        end,
    },
}