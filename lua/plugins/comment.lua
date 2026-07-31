-- echasnovski/mini.comment
-- 智能注释（替代 numToStr/Comment.nvim：后者 2024-06 起停更）
-- 默认键位与 Comment.nvim 兼容：gcc 行注释、gc{motion}、gbc 块注释、gb{motion}
-- https://github.com/echasnovski/mini.comment

return {
    {
        "echasnovski/mini.comment",
        -- 不延迟加载，确保注释功能立即可用
        lazy = false,
        config = function()
            require("mini.comment").setup({
                options = {
                    -- 注释符号与行之间加空格
                    padding = true,
                    -- 光标保持原位
                    sticky = true,
                    -- 起始/结束空白（treesitter 感知）
                    start_after_line_prefix = false,
                },
                mappings = {
                    comment = "gc",        -- 注释操作符
                    comment_line = "gcc",  -- 注释当前行
                    comment_visual = "gc", -- 可视模式注释
                    textobject = "gb",     -- 块注释文本对象
                },
            })
        end,
    },
}
