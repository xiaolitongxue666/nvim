-- lukas-reineke/indent-blankline.nvim

-- 为 Neovim 添加缩进参考线的插件
-- 使用 Neovim 的虚拟文本功能，不使用 conceal

-- https://github.com/lukas-reineke/indent-blankline.nvim

return {
    {
        -- 插件名称
        "lukas-reineke/indent-blankline.nvim",
        -- 版本 3 的主入口点
        main = "ibl",
        -- 懒加载事件
        event = { "BufReadPost", "BufNewFile" },
        -- 配置选项
        opts = {
            -- 缩进线配置
            indent = {
                char = "│", -- 缩进线字符
                tab_char = "│", -- Tab 缩进字符
                smart_indent_cap = true, -- 智能缩进上限
            },
            -- 空白字符配置
            whitespace = {
                highlight = { "Whitespace", "NonText" },
                remove_blankline_trail = false, -- 保留空行尾部的空白字符
            },
            -- 作用域配置（需要 treesitter 支持）
            scope = {
                enabled = true, -- 启用作用域高亮
                show_start = true, -- 显示作用域开始
                show_end = true, -- 显示作用域结束
                injected_languages = false, -- 不在注入语言中显示作用域
                highlight = { "Function", "Label" }, -- 作用域高亮组
                priority = 500, -- 作用域优先级
            },
            -- 排除的文件类型
            exclude = {
                filetypes = {
                    "help", -- 帮助文档
                    "alpha", -- Alpha 启动页
                    "dashboard", -- 仪表板
                    "neo-tree", -- Neo-tree 文件浏览器
                    "Trouble", -- Trouble 诊断列表
                    "trouble", -- trouble 小写版本
                    "lazy", -- Lazy 插件管理器
                    "mason", -- Mason LSP 管理器
                    "notify", -- 通知插件
                    "toggleterm", -- 终端插件
                    "lazyterm", -- Lazy 终端
                    "lspinfo", -- LSP 信息
                    "packer", -- Packer 插件管理器
                    "checkhealth", -- 健康检查
                    "man", -- 手册页
                    "gitcommit", -- Git 提交
                    "TelescopePrompt", -- Telescope 提示
                    "TelescopeResults", -- Telescope 结果
                    "", -- 空文件类型
                },
                buftypes = {
                    "terminal", -- 终端缓冲区
                    "nofile", -- 无文件缓冲区
                    "quickfix", -- 快速修复列表
                    "prompt", -- 提示缓冲区
                },
            },
        },
    },
}