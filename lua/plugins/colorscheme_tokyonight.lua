-- folke/tokyonight.nvim

-- 用 Lua 编写的简洁、深色 Neovim 主题

-- https://github.com/folke/tokyonight.nvim#storm

return {
    {
        -- 插件名称
        "folke/tokyonight.nvim",
        -- 当为 true 时，插件只在需要时加载
        lazy = false,
        -- 仅对启动插件 (lazy=false) 有用，强制某些插件优先加载
        priority = 1000,
        -- Opts 是一个将传递给 Plugin.config() 函数的表。设置此值将隐含 Plugin.config()
        opts = {},
        -- 插件加载时执行的配置函数
        config = function()
            require("tokyonight").setup({
                -- 你的配置在这里
                -- 或者留空使用默认设置
                style = "moon", -- 主题有三种样式：`storm`、`moon`、更深色的 `night` 和 `day`
                light_style = "day", -- 当背景设置为浅色时使用的主题
                transparent = true, -- 启用此选项以禁用设置背景颜色
                terminal_colors = true, -- 配置在 Neovim 中打开 `:terminal` 时使用的颜色
                styles = {
                    -- 应用于不同语法组的样式
                    -- 值是任何有效的 attr-list 值，参见 `:help nvim_set_hl`
                    comments = { italic = true },
                    keywords = { italic = true },
                    functions = {},
                    variables = {},
                    -- 背景样式。可以是 "dark"、"transparent" 或 "normal"
                    sidebars = "normal", -- 侧边栏样式，见下文
                    floats = "dark", -- 浮动窗口样式
                },
                sidebars = { "qf", "help" }, -- 在类似侧边栏的窗口上设置更深的背景。例如：`["qf", "vista_kind", "terminal", "packer"]`
                day_brightness = 0.3, -- 调整 **Day** 样式颜色的亮度。0 到 1 之间的数字，从暗淡到鲜艳的颜色
                hide_inactive_statusline = false, -- 启用此选项将隐藏非活动状态栏并用细边框替换。应该与标准 **StatusLine** 和 **LuaLine** 一起工作
                dim_inactive = false, -- 使非活动窗口变暗
                lualine_bold = false, -- 当为 `true` 时，lualine 主题中的节标题将为粗体

                --- 你可以覆盖特定的颜色组以使用其他组或十六进制颜色
                --- 函数将使用 ColorScheme 表调用
                ---@param colors ColorScheme
                on_colors = function(colors) end,

                --- 你可以覆盖特定的高亮以使用其他组或十六进制颜色
                --- 函数将使用 Highlights 和 ColorScheme 表调用
                ---@param highlights Highlights
                ---@param colors ColorScheme
                on_highlights = function(highlights, colors) end,
            })
            -- 设置配色方案
            vim.cmd[[colorscheme tokyonight]]
        end
    },
}
