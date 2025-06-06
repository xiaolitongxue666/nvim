-- folke/tokyonight.nvim

-- 🏙 用 Lua 编写的简洁、深色 Neovim 主题，支持 LSP、Treesitter 和众多插件

-- 官方文档：https://github.com/folke/tokyonight.nvim

return {
    {
        -- 插件名称
        "folke/tokyonight.nvim",
        -- 不延迟加载，确保主题在启动时立即可用
        lazy = false,
        -- 设置最高优先级，确保主题在其他插件之前加载
        priority = 1000,
        -- 插件配置函数
        config = function()
            require("tokyonight").setup({
                -- 主题样式："storm"、"moon"、"night"、"day"
                style = "moon",
                -- 浅色模式时使用的样式
                light_style = "day",
                -- 启用透明背景
                transparent = true,
                -- 配置终端颜色
                terminal_colors = true,
                -- 语法高亮样式配置
                styles = {
                    -- 注释样式：斜体
                    comments = { italic = true },
                    -- 关键字样式：斜体
                    keywords = { italic = true },
                    -- 函数样式：默认
                    functions = {},
                    -- 变量样式：默认
                    variables = {},
                    -- 侧边栏样式："dark"、"transparent" 或 "normal"
                    sidebars = "normal",
                    -- 浮动窗口样式："dark"、"transparent" 或 "normal"
                    floats = "dark",
                },
                -- 设置侧边栏窗口类型，这些窗口将使用更深的背景
                sidebars = { "qf", "help", "vista_kind", "terminal", "packer" },
                -- Day 样式的亮度调节（0-1 之间）
                day_brightness = 0.3,
                -- 隐藏非活动状态栏
                hide_inactive_statusline = false,
                -- 使非活动窗口变暗
                dim_inactive = false,
                -- Lualine 主题中的节标题是否加粗
                lualine_bold = false,
                -- 缓存编译的主题以提高性能
                cache = true,

                --- 自定义颜色回调函数
                --- 可以覆盖特定的颜色组
                ---@param colors ColorScheme
                on_colors = function(colors)
                    -- 在这里自定义颜色
                end,

                --- 自定义高亮回调函数
                --- 可以覆盖特定的高亮组
                ---@param highlights Highlights
                ---@param colors ColorScheme
                on_highlights = function(highlights, colors)
                    -- 在这里自定义高亮
                end,
            })
            
            -- 应用 TokyoNight 配色方案
            vim.cmd.colorscheme("tokyonight")
        end,
    },
}
