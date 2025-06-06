-- numToStr/Comment.nvim

-- 🧠 Neovim 的智能且强大的注释插件，支持 Treesitter、点重复、左右/上下移动、钩子等功能

-- 官方文档：https://github.com/numToStr/Comment.nvim

return {
    {
        -- 插件名称
        "numToStr/Comment.nvim",
        -- 不延迟加载，确保注释功能立即可用
        lazy = false,
        -- 插件配置
        opts = {
            -- 在注释和行之间添加空格
            padding = true,
            -- 光标是否应保持在其位置
            sticky = true,
            -- 在（取消）注释时要忽略的行
            ignore = nil,
            -- 普通模式下切换映射的左侧
            toggler = {
                -- 行注释切换键映射
                line = 'gcc',
                -- 块注释切换键映射
                block = 'gbc',
            },
            -- 普通模式和可视模式下操作符待定映射的左侧
            opleader = {
                -- 行注释键映射
                line = 'gc',
                -- 块注释键映射
                block = 'gb',
            },
            -- 额外映射的左侧
            extra = {
                -- 在上方添加注释
                above = 'gcO',
                -- 在下方添加注释
                below = 'gco',
                -- 在行尾添加注释
                eol = 'gcA',
            },
            -- 启用键绑定
            -- 注意：如果设为 false，插件将不会创建任何映射
            mappings = {
                -- 操作符待定映射：`gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
                basic = true,
                -- 额外映射：`gco`、`gcO`、`gcA`
                extra = true,
            },
            -- 在（取消）注释之前调用的函数
            pre_hook = nil,
            -- 在（取消）注释之后调用的函数
            post_hook = nil,
        },
    },
}