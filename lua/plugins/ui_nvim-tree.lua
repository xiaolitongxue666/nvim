-- nvim-tree/nvim-tree.lua

-- A file explorer tree for neovim written in lua

-- https://github.com/nvim-tree/nvim-tree.lua

--[[
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
--]]

-- 插件已暂时注释，如需重新启用请移除 --[[ 和 --]] 注释符号
return {}