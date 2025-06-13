-- aerial.nvim
-- https://github.com/stevearc/aerial.nvim

return {
    {
        -- 插件名称
        "stevearc/aerial.nvim",
        -- 依赖项
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons", -- 可选：图标支持
        },
        -- 在读取文件后懒加载
        event = "BufReadPost",
        -- 命令懒加载
        cmd = {
            "AerialToggle",
            "AerialOpen",
            "AerialClose",
            "AerialNext",
            "AerialPrev",
        },
        -- 键位映射
        keys = {
            {
                "<leader>a",
                "<cmd>AerialToggle<CR>",
                desc = "切换代码大纲",
            },
            {
                "<leader>A",
                "<cmd>AerialToggle!<CR>",
                desc = "切换代码大纲（浮动窗口）",
            },
            {
                "[s",
                "<cmd>AerialPrev<CR>",
                desc = "上一个符号",
            },
            {
                "]s",
                "<cmd>AerialNext<CR>",
                desc = "下一个符号",
            },
        },
        -- 插件配置选项
        opts = {
            -- 后端优先级（必需配置）
            backends = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
            -- 附加模式：window模式确保显示正确的缓冲区符号
            attach_mode = "window",
            -- 自动关闭事件
            close_automatic_events = { "unfocus" },
            -- 布局配置
            layout = {
                max_width = { 40, 0.2 },
                width = nil,
                min_width = 10,
                win_opts = {},
                default_direction = "prefer_left",
                placement = "edge",
                resize_to_content = true,
                preserve_equality = false,
            },
            -- 在附加到缓冲区时设置键位映射
            on_attach = function(bufnr)
                vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
                vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
            end,
            -- 显示指南线
            show_guides = true,
            -- 过滤器配置
            filter_kind = {
                "Class",
                "Constructor",
                "Enum",
                "Function",
                "Interface",
                "Module",
                "Method",
                "Struct",
                "Variable",  -- 添加变量
                "Constant",  -- 添加常量
                "Field",     -- 添加字段
                "TypeParameter", -- 添加类型参数
            },
            -- 高亮配置
            highlight_mode = "split_width",
            -- 高亮最近的符号
            highlight_closest = true,
            -- 高亮当前符号
            highlight_on_hover = false,
            -- 高亮当前符号跳转
            highlight_on_jump = 300,
            -- 图标配置
            icons = {},
            -- 忽略的文件类型
            ignore = {
                filetypes = {},
                buftypes = "special",
                wintypes = "special",
            },
            -- 管理折叠
            manage_folds = false,
            -- 链接树状结构和折叠
            link_folds_to_tree = false,
            -- 链接树状结构和光标
            link_tree_to_folds = true,
            -- 导航窗口配置
            nav = {
                border = "rounded",
                max_height = 0.9,
                min_height = { 10, 0.1 },
                max_width = 0.5,
                min_width = { 0.2, 20 },
                win_opts = {
                    cursorline = true,
                    winblend = 10,
                },
                -- 自动跳转
                autojump = false,
                -- 预览
                preview = false,
                -- 键位映射
                keymaps = {
                    ["<CR>"] = "actions.jump",
                    ["<2-LeftMouse>"] = "actions.jump",
                    ["<C-v>"] = "actions.jump_vsplit",
                    ["<C-s>"] = "actions.jump_split",
                    ["h"] = "actions.left",
                    ["l"] = "actions.right",
                    ["<C-c>"] = "actions.close",
                },
            },
            -- 浮动窗口配置
            float = {
                border = "rounded",
                relative = "cursor",
                max_height = 0.9,
                height = nil,
                min_height = { 8, 0.1 },
                override = function(conf, source_winid)
                    conf.anchor = "NE"
                    conf.col = conf.col + 1
                    conf.row = conf.row + 1
                    return conf
                end,
            },
            -- treesitter 配置
            treesitter = {
                update_delay = 300,
            },
            -- lsp 配置
            lsp = {
                diagnostics_trigger_update = true,
                update_when_errors = true,
                update_delay = 300,
                priority = {
                    pyright = 10,
                },
            },
            -- markdown 配置
            markdown = {
                update_delay = 300,
            },
            -- asciidoc 配置
            asciidoc = {
                update_delay = 300,
            },
            -- man 配置
            man = {
                update_delay = 300,
            },
        },
        -- 插件配置函数
        config = function(_, opts)
            require("aerial").setup(opts)
        end,
    },
}