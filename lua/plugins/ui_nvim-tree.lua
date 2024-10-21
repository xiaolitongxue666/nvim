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