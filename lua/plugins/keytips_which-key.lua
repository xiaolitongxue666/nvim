-- folke/which-key.nvim

-- 显示键位绑定提示的弹窗，帮助记忆 Neovim 键位映射

-- https://github.com/folke/which-key.nvim

return {
    {
        -- 插件名称
        "folke/which-key.nvim",
        -- 懒加载事件
        event = "VeryLazy",
        -- 初始化函数，在启动时总是执行
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
        end,
        -- 配置选项，将传递给 Plugin.config() 函数
        opts = {
            -- 预设样式："classic"（经典）、"modern"（现代）、"helix"（helix风格）或 false（自定义）
            preset = "classic",
            -- 显示弹窗前的延迟时间（毫秒）
            delay = function(ctx)
                return ctx.plugin and 0 or 200
            end,
            -- 过滤器函数，用于过滤要显示的映射
            filter = function(mapping)
                -- 示例：排除没有描述的映射
                -- return mapping.desc and mapping.desc ~= ""
                return true
            end,
            -- 键位映射规范
            spec = {},
            -- 当检测到映射问题时显示警告
            notify = true,
            -- 触发器配置
            triggers = {
                { "<auto>", mode = "nxso" },
            },
            -- 延迟函数，用于某些模式下的延迟显示
            defer = function(ctx)
                return ctx.mode == "V" or ctx.mode == "<C-V>"
            end,
            -- 插件功能配置
            plugins = {
                marks = true, -- 在 ' 和 ` 上显示标记列表
                registers = true, -- 在普通模式下按 " 或插入模式下按 <C-r> 显示寄存器
                -- 拼写建议
                spelling = {
                    enabled = true, -- 启用拼写建议，按 z= 时显示 WhichKey
                    suggestions = 20, -- 显示的建议数量
                },
                -- 预设帮助
                presets = {
                    operators = true, -- 为操作符（如 d, y 等）添加帮助
                    motions = true, -- 为动作添加帮助
                    text_objects = true, -- 为文本对象添加帮助
                    windows = true, -- <c-w> 的默认绑定
                    nav = true, -- 窗口操作的其他绑定
                    z = true, -- 以 z 为前缀的绑定（折叠、拼写等）
                    g = true, -- 以 g 为前缀的绑定
                },
            },
            -- 窗口配置
            win = {
                -- 不允许弹窗与光标重叠
                no_overlap = true,
                -- 窗口内边距 [上下, 左右]
                padding = { 1, 2 },
                title = true,
                title_pos = "center",
                zindex = 1000,
                -- 额外的 vim.bo 选项
                bo = {},
                -- 额外的 vim.wo 选项
                wo = {
                    -- winblend = 10, -- 窗口透明度，0-100，0为完全不透明，100为完全透明
                },
            },
            -- 布局配置
            layout = {
                width = { min = 20 }, -- 列的最小和最大宽度
                spacing = 3, -- 列之间的间距
            },
            -- 键位配置
            keys = {
                scroll_down = "<c-d>", -- 在弹窗内向下滚动的绑定
                scroll_up = "<c-u>", -- 在弹窗内向上滚动的绑定
            },
            -- 排序配置
            sort = { "local", "order", "group", "alphanum", "mod" },
        },
        -- 键位映射
        keys = {
            {
                "<leader>?",
                function()
                    require("which-key").show({ global = false })
                end,
                desc = "缓冲区本地键位映射 (which-key)",
            },
        },
    },
}