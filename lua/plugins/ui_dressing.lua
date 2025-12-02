-- 改进 Neovim 默认 vim.ui 界面的插件
-- 提供更美观的选择和输入界面

-- https://github.com/stevearc/dressing.nvim

-- 警告：此插件已被作者归档，推荐使用 snacks.nvim 作为替代
-- 替代方案：https://github.com/folke/snacks.nvim

return {
    {
        "stevearc/dressing.nvim",
        -- 提前加载，避免在 fast-event 中动态加载导致错误
        event = "UIEnter",
        -- 插件配置选项
        opts = {
            input = {
                -- 设置为 false 以禁用输入 UI
                enabled = true,
                -- 默认提示字符串
                default_prompt = "Input:",
                -- 当输入为空时是否修剪提示
                trim_prompt = true,
                -- 输入框的标题
                title_pos = "left",
                -- 插入模式开始位置
                insert_only = true,
                -- 开始插入模式
                start_in_insert = true,
                -- 边框样式
                border = "rounded",
                -- 相对位置
                relative = "cursor",
                -- 首选宽度
                prefer_width = 40,
                -- 宽度
                width = nil,
                -- 最大宽度
                max_width = { 140, 0.9 },
                -- 最小宽度
                min_width = { 20, 0.2 },
                -- 窗口配置
                win_options = {
                    -- 窗口混合
                    winblend = 10,
                    -- 换行
                    wrap = false,
                    -- 列表字符
                    list = true,
                    listchars = "precedes:…,extends:…",
                    -- 侧边滚动偏移
                    sidescrolloff = 0,
                },
                -- 覆盖特定命令的配置
                override = function(conf)
                    -- 这些是传递给 nvim_open_win 的配置选项
                    conf.col = -1
                    conf.row = 0
                    return conf
                end,
                -- 查看 :help dressing_get_config
                get_config = nil,
            },
            select = {
                -- 设置为 false 以禁用选择 UI
                enabled = true,
                -- 优先级顺序的后端
                backend = { "builtin", "nui", "telescope", "fzf_lua", "fzf" },
                -- 修剪提示
                trim_prompt = true,
                -- 用于 vim.ui.select 的选项
                telescope = require("telescope.themes").get_dropdown({
                    -- 即使只有一个项目也显示
                    initial_mode = "normal",
                }),
                -- 用于 fzf-lua 的选项
                fzf_lua = {
                    -- winopts = {
                    --   height = 0.5,
                    --   width = 0.5,
                    -- },
                },
                -- 用于 nui 的选项
                nui = {
                    position = "50%",
                    size = nil,
                    relative = "editor",
                    border = {
                        style = "rounded",
                    },
                    buf_options = {
                        swapfile = false,
                        filetype = "DressingSelect",
                    },
                    win_options = {
                        winblend = 10,
                    },
                    max_width = 80,
                    max_height = 40,
                    min_width = 40,
                    min_height = 10,
                },
                -- 用于内置选择的选项
                builtin = {
                    -- 显示数字以便快速选择
                    show_numbers = true,
                    -- 边框样式
                    border = "rounded",
                    -- 相对位置
                    relative = "editor",
                    -- 窗口配置
                    win_options = {
                        winblend = 10,
                    },
                    -- 宽度和高度可以是函数
                    width = nil,
                    max_width = { 140, 0.8 },
                    min_width = { 40, 0.2 },
                    height = nil,
                    max_height = 0.9,
                    min_height = { 10, 0.2 },
                    -- 覆盖特定命令的配置
                    override = function(conf)
                        vim.schedule(function()
                            local buf = vim.api.nvim_get_current_buf()
                            local opts = { buffer = buf, silent = true, nowait = true }
                            vim.keymap.set("n", "i", "k", opts)
                            vim.keymap.set("n", "k", "j", opts)
                        end)
                        return conf
                    end,
                },
                -- 查看 :help dressing_get_config
                get_config = function(opts)
                    if opts.kind == "codeaction" then
                        return {
                            backend = "nui",
                            nui = {
                                relative = "cursor",
                                max_width = 60,
                            }
                        }
                    end
                end
            },
        },
        -- 插件初始化时执行
        init = function()
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.ui.select = function(...)
                require("lazy").load({ plugins = { "dressing.nvim" } })
                return vim.ui.select(...)
            end
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.ui.input = function(...)
                require("lazy").load({ plugins = { "dressing.nvim" } })
                return vim.ui.input(...)
            end
        end,
    },
}
