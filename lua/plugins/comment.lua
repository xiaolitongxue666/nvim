-- numToStr/Comment.nvim

-- neovim 的智能且强大的注释插件

-- https://github.com/numToStr/Comment.nvim

return {
    {
        -- 插件名称
        "numToStr/Comment.nvim",
        -- Opts 是一个将传递给 Plugin.config() 函数的表。设置此值将隐含 Plugin.config()
        opts = {
            -- 在此处添加任何选项
        },
        -- 当为 true 时，插件只在需要时加载
        lazy = false,
        -- 插件加载时执行配置
        config = function()
            require("Comment").setup()
            -- 默认按键映射
            -- https://github.com/numToStr/Comment.nvim#configuration-optional
        end
    },
}