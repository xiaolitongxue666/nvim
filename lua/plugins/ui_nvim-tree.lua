-- nvim-tree/nvim-tree.lua

-- A file explorer tree for neovim written in lua

-- https://github.com/nvim-tree/nvim-tree.lua

return {
    {
        -- Plug name
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("nvim-tree").setup({
                filters = {
                    dotfiles = true,
                },
            })
        end,
    },
}