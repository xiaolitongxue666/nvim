-- opencode.nvim
-- 集成 opencode AI 助手到 Neovim
-- 提供编辑器感知的研究、审查和请求功能
--
-- https://github.com/NickvanDyke/opencode.nvim

return {
    {
        "NickvanDyke/opencode.nvim",
        dependencies = {
            -- 推荐用于 ask() 和 select() 功能
            -- 如果使用 snacks provider，则必需
            ---@module 'snacks' <- Loads `snacks.nvim` types for configuration intellisense.
            {
                "folke/snacks.nvim",
                opts = {
                    input = {},
                    picker = {},
                    terminal = {},
                },
            },
        },
        cmd = {
            "OpencodeAsk",
            "OpencodeSelect",
            "OpencodeToggle",
            "OpencodePrompt",
            "OpencodeCommand",
        },
        keys = {
            -- 主要功能快捷键
            {
                "<leader>aia",  -- ai = AI, a = ask
                function()
                    require("opencode").ask("@this: ", { submit = true })
                end,
                desc = "询问 opencode（当前选择）",
                mode = { "n", "x" },
            },
            {
                "<leader>ais",  -- ai = AI, s = select
                function()
                    require("opencode").select()
                end,
                desc = "选择 opencode 操作",
                mode = { "n", "x" },
            },
            {
                "<leader>ait",  -- ai = AI, t = toggle
                function()
                    require("opencode").toggle()
                end,
                desc = "切换 opencode",
                mode = { "n", "t" },
            },
            -- 操作符模式（支持范围和点重复）
            {
                "go",
                function()
                    return require("opencode").operator("@this ")
                end,
                desc = "添加范围到 opencode",
                mode = "n",
                expr = true,
            },
            {
                "goo",
                function()
                    return require("opencode").operator("@this ") .. "_"
                end,
                desc = "添加当前行到 opencode",
                mode = "n",
                expr = true,
            },
            -- 会话控制
            {
                "<leader>aiu",  -- ai = AI, u = up
                function()
                    require("opencode").command("session.half.page.up")
                end,
                desc = "向上滚动 opencode 会话",
                mode = "n",
            },
            {
                "<leader>aid",  -- ai = AI, d = down
                function()
                    require("opencode").command("session.half.page.down")
                end,
                desc = "向下滚动 opencode 会话",
                mode = "n",
            },
            {
                "<leader>aii",  -- ai = AI, i = interrupt
                function()
                    require("opencode").command("session.interrupt")
                end,
                desc = "中断 opencode 会话",
                mode = "n",
            },
            -- 窗口导航
            {
                "<leader>aie",  -- ai = AI, e = edit (返回主编辑窗口)
                function()
                    local current_win = vim.api.nvim_get_current_win()
                    local current_buf = vim.api.nvim_win_get_buf(current_win)
                    local windows = vim.api.nvim_list_wins()
                    
                    -- 找到第一个普通编辑窗口（跳过终端、帮助、quickfix、opencode 等特殊窗口）
                    for _, win in ipairs(windows) do
                        if win ~= current_win then
                            local buf = vim.api.nvim_win_get_buf(win)
                            local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
                            local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
                            local bufname = vim.api.nvim_buf_get_name(buf)
                            
                            -- 跳过特殊窗口类型
                            -- buftype: "" 表示普通文件缓冲区
                            -- 跳过: 终端、帮助、quickfix、opencode 终端窗口等
                            if buftype == "" 
                                and filetype ~= "help" 
                                and filetype ~= "qf"
                                and not string.match(bufname, "opencode") then
                                -- 找到普通编辑窗口，切换过去（不隐藏当前窗口）
                                vim.api.nvim_set_current_win(win)
                                return
                            end
                        end
                    end
                    
                    -- 如果找不到合适的窗口，尝试切换到上一个窗口
                    local prev_win = vim.fn.winnr("#")
                    if prev_win > 0 and prev_win ~= vim.fn.winnr() and vim.fn.winbufnr(prev_win) ~= -1 then
                        vim.cmd(prev_win .. "wincmd w")
                    else
                        -- 最后尝试使用默认的窗口切换（切换到上一个窗口）
                        vim.cmd("wincmd p")
                    end
                end,
                desc = "返回主编辑窗口（不隐藏 opencode）",
                mode = { "n", "t" },
            },
        },
        config = function()
            -- 若 install.sh 注入了路径则使用，否则依赖 PATH 中的 opencode（多 OS 兼容）
            local opencode_cmd = (vim.g.opencode_cmd and vim.g.opencode_cmd ~= "") and vim.g.opencode_cmd or "opencode"
            ---@type opencode.Opts
            vim.g.opencode_opts = {
                -- Provider 配置
                -- opencode.nvim 会自动检测 CWD 中已运行的 opencode 实例
                -- 如果找不到已存在的实例，才会使用配置的 provider 启动新的实例
                -- 重要：必须使用 --port 标志来暴露服务器
                provider = {
                    -- 可选值: "terminal", "snacks", "kitty", "wezterm", "tmux", 或自定义函数
                    -- 如果已经在终端运行了 opencode --port，插件会自动检测到，不会启动新的实例
                    enabled = "snacks", -- 使用 snacks provider（推荐，更稳定）
                    snacks = {
                        cmd = opencode_cmd,
                        args = { "--port", "0" }, -- 使用随机端口
                    },
                    -- terminal provider 配置（作为后备）
                    terminal = {
                        cmd = opencode_cmd,
                        args = { "--port", "0" },
                    },
                },
                -- 事件配置
                events = {
                    -- 当 opencode 编辑文件时自动重载缓冲区
                    reload = true,
                },
                -- 输入提示配置
                ask = {
                    -- 使用 snacks.input 时的补全源配置
                    -- 如果使用 blink.cmp，可以配置补全源
                    -- blink_cmp_sources = { ... },
                },
            }

            -- opencode.nvim 需要 autoread 来重载编辑后的文件
            vim.o.autoread = true

            -- 可选：处理 opencode 事件
            -- vim.api.nvim_create_autocmd("User", {
            --     pattern = "OpencodeEvent:*",
            --     callback = function(args)
            --         ---@type opencode.cli.client.Event
            --         local event = args.data.event
            --         ---@type number
            --         local port = args.data.port
            --
            --         -- 处理事件
            --         if event.type == "session.idle" then
            --             vim.notify("opencode 已完成响应", vim.log.levels.INFO)
            --         end
            --     end,
            -- })
        end,
    },
}

