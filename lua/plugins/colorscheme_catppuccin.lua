-- catppuccin/nvim
--
-- 🍨 Soothing pastel theme for (Neo)vim
--
-- 官方文档：https://github.com/catppuccin/nvim

return {
    {
        -- 插件名称
        "catppuccin/nvim",
        name = "catppuccin",
        -- 不延迟加载，确保主题在启动时立即可用
        lazy = false,
        -- 设置最高优先级，确保主题在其他插件之前加载
        priority = 1000,
        -- 插件配置函数
        config = function()
            require("catppuccin").setup({
                -- 主题风格："latte"、"frappe"、"macchiato"、"mocha"、"auto"
                flavour = "mocha", -- auto 会根据背景自动选择
                -- 背景模式对应的主题
                background = {
                    light = "latte",
                    dark = "mocha",
                },
                -- 启用透明背景
                transparent_background = true,
                -- 浮动窗口配置
                float = {
                    transparent = false, -- 浮动窗口不透明
                    solid = false, -- 不使用实心样式
                },
                -- 显示缓冲区末尾的 '~' 字符
                show_end_of_buffer = false,
                -- 设置终端颜色
                term_colors = true,
                -- 非活动窗口变暗
                dim_inactive = {
                    enabled = false, -- 禁用非活动窗口变暗
                    shade = "dark",
                    percentage = 0.15,
                },
                -- 强制样式选项
                no_italic = false, -- 允许斜体
                no_bold = false, -- 允许粗体
                no_underline = false, -- 允许下划线
                -- 语法高亮样式配置
                styles = {
                    comments = { "italic" }, -- 注释使用斜体
                    conditionals = { "italic" }, -- 条件语句使用斜体
                    loops = {},
                    functions = {},
                    keywords = {},
                    strings = {},
                    variables = {},
                    numbers = {},
                    booleans = {},
                    properties = {},
                    types = {},
                    operators = {},
                },
                -- LSP 样式配置
                lsp_styles = {
                    virtual_text = {
                        errors = { "italic" },
                        hints = { "italic" },
                        warnings = { "italic" },
                        information = { "italic" },
                        ok = { "italic" },
                    },
                    underlines = {
                        errors = { "underline" },
                        hints = { "underline" },
                        warnings = { "underline" },
                        information = { "underline" },
                        ok = { "underline" },
                    },
                    inlay_hints = {
                        background = true,
                    },
                },
                -- 颜色覆盖（自定义颜色）
                color_overrides = {},
                -- 自定义高亮组
                custom_highlights = {},
                -- 启用默认集成
                default_integrations = true,
                -- 自动集成（自动检测并集成已安装的插件）
                auto_integrations = false,
                -- 插件集成配置
                integrations = {
                    cmp = true, -- nvim-cmp
                    gitsigns = true, -- gitsigns
                    nvimtree = true, -- nvim-tree
                    notify = false, -- nvim-notify
                    mini = {
                        enabled = true,
                        indentscope_color = "",
                    },
                    -- 根据已安装的插件启用相应集成
                    treesitter = true,
                    treesitter_context = true,
                    telescope = true,
                    which_key = true,
                    indent_blankline = {
                        enabled = true,
                        scope_color = "",
                    },
                    native_lsp = {
                        enabled = true,
                        virtual_text = {
                            errors = { "italic" },
                            hints = { "italic" },
                            warnings = { "italic" },
                            information = { "italic" },
                            ok = { "italic" },
                        },
                        underlines = {
                            errors = { "underline" },
                            hints = { "underline" },
                            warnings = { "underline" },
                            information = { "underline" },
                            ok = { "underline" },
                        },
                        inlay_hints = {
                            background = true,
                        },
                    },
                    lualine = true,
                    bufferline = true,
                    toggleterm = true,
                    dap = {
                        enabled = true,
                        enable_ui = true,
                    },
                    neotree = true,
                    noice = true,
                },
            })

            -- 应用 Catppuccin 配色方案
            -- 可选的主题：catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha
            vim.cmd.colorscheme("catppuccin")
        end,
    },
}

