-- 现代化的 Neovim UI 替换插件
-- 完全替换消息、命令行和弹出菜单的 UI

-- https://github.com/folke/noice.nvim

return {
    {
        -- 插件名称
        "folke/noice.nvim",
        -- 依赖项
        dependencies = {
            "MunifTanjim/nui.nvim",
            "rcarriga/nvim-notify",
        },
        -- 在 VeryLazy 事件时加载
        event = "VeryLazy",
        -- 插件配置选项
        opts = {
            -- LSP 配置
            lsp = {
                -- 覆盖 markdown 渲染
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true,
                },
                -- 悬停文档配置
                hover = {
                    enabled = true,
                    silent = false,
                },
                -- 签名帮助配置
                signature = {
                    enabled = true,
                    auto_open = {
                        enabled = true,
                        trigger = true,
                        luasnip = true,
                        throttle = 50,
                    },
                },
                -- 消息配置
                message = {
                    enabled = true,
                    view = "notify",
                    opts = {},
                },
                -- 文档配置
                documentation = {
                    view = "hover",
                    opts = {
                        lang = "markdown",
                        replace = true,
                        render = "plain",
                        format = { "{message}" },
                        win_options = { concealcursor = "n", conceallevel = 3 },
                    },
                },
            },
            -- 消息路由配置
            routes = {
                {
                    filter = {
                        event = "msg_show",
                        any = {
                            { find = "%d+L, %d+B" },
                            { find = "; after #%d+" },
                            { find = "; before #%d+" },
                            { find = "^E486: Pattern not found" },
                            { find = "^E486: 模式未找到" },
                        },
                    },
                    view = "mini",
                },
                {
                    filter = {
                        event = "msg_show",
                        find = "written",
                    },
                    opts = { skip = true },
                },
                {
                    filter = {
                        event = "msg_show",
                        kind = "search_count",
                    },
                    opts = { skip = true },
                },
                {
                    filter = {
                        event = "msg_show",
                        find = "more line",
                    },
                    opts = { skip = true },
                },
                {
                    filter = {
                        event = "msg_show",
                        find = "fewer line",
                    },
                    opts = { skip = true },
                },
            },
            -- 预设配置
            presets = {
                -- 底部搜索
                bottom_search = true,
                -- 命令面板
                command_palette = true,
                -- 长消息分割到新窗口
                long_message_to_split = true,
                -- 增量重命名
                inc_rename = true,
                -- LSP 悬停边框
                lsp_doc_border = false,
            },
            -- 命令行配置
            cmdline = {
                enabled = true,
                view = "cmdline_popup",
                opts = {},
                format = {
                    cmdline = { pattern = "^:", icon = "", lang = "vim" },
                    search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
                    search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
                    filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
                    lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
                    help = { pattern = "^:%s*he?l?p?%s+", icon = "" },
                    input = {},
                },
            },
            -- 消息配置
            messages = {
                enabled = true,
                view = "notify",
                view_error = "notify",
                view_warn = "notify",
                view_history = "messages",
                view_search = "virtualtext",
            },
            -- 弹出菜单配置
            popupmenu = {
                enabled = true,
                backend = "nui",
                kind_icons = {},
            },
            -- 重定向配置
            redirect = {
                view = "popup",
                filter = { event = "msg_show" },
            },
            -- 命令配置
            commands = {
                history = {
                    view = "split",
                    opts = { enter = true, format = "details" },
                    filter = {
                        any = {
                            { event = "notify" },
                            { error = true },
                            { warning = true },
                            { event = "msg_show", kind = { "" } },
                            { event = "lsp", kind = "message" },
                        },
                    },
                },
                last = {
                    view = "popup",
                    opts = { enter = true, format = "details" },
                    filter = {
                        any = {
                            { event = "notify" },
                            { error = true },
                            { warning = true },
                            { event = "msg_show", kind = { "" } },
                            { event = "lsp", kind = "message" },
                        },
                    },
                    filter_opts = { count = 1 },
                },
                errors = {
                    view = "popup",
                    opts = { enter = true, format = "details" },
                    filter = { error = true },
                    filter_opts = { reverse = true },
                },
            },
            -- 通知配置
            notify = {
                enabled = true,
                view = "notify",
            },
            -- 健康检查配置
            health = {
                checker = false,
            },
            -- 智能移动配置
            smart_move = {
                enabled = true,
                excluded_filetypes = { "cmp_menu", "cmp_docs", "notify" },
            },
            -- 节流配置
            throttle = 1000 / 30,
        },
        -- 按键映射
        keys = {
            { "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "重定向命令行" },
            { "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice 最后消息" },
            { "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice 历史记录" },
            { "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice 所有消息" },
            { "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "关闭所有通知" },
            { "<leader>sne", function() require("noice").cmd("errors") end, desc = "Noice 错误消息" },
            {
                "<c-f>",
                function()
                    if not require("noice.lsp").scroll(4) then
                        return "<c-f>"
                    end
                end,
                silent = true,
                expr = true,
                desc = "向前滚动",
                mode = { "i", "n", "s" },
            },
            {
                "<c-b>",
                function()
                    if not require("noice.lsp").scroll(-4) then
                        return "<c-b>"
                    end
                end,
                silent = true,
                expr = true,
                desc = "向后滚动",
                mode = { "i", "n", "s" },
            },
        },
        -- 插件配置函数
        config = function(_, opts)
            -- 如果 treesitter 可用，启用 markdown 和 regex 高亮
            if type(opts.presets.lsp_doc_border) == "boolean" then
                opts.presets.lsp_doc_border = {
                    views = {
                        hover = {
                            border = {
                                style = "rounded",
                            },
                        },
                    },
                }
            end
            
            require("noice").setup(opts)
        end,
    },
}