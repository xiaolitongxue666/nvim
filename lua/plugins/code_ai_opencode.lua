-- opencode.nvim
-- 集成 opencode AI 助手到 Neovim
-- 提供编辑器感知的研究、审查和请求功能
--
-- https://github.com/NickvanDyke/opencode.nvim

return {
    {
        -- 插件名称
        "NickvanDyke/opencode.nvim",
        -- 依赖项
        dependencies = {
            -- 推荐用于 ask() 和 select() 功能
            -- 如果使用 snacks provider，则必需
            {
                "folke/snacks.nvim",
                opts = {
                    input = {},
                    picker = {},
                    terminal = {},
                },
            },
        },
        -- 命令懒加载（触发插件加载）
        cmd = {
            "OpencodeAsk",
            "OpencodeSelect",
            "OpencodeToggle",
            "OpencodePrompt",
            "OpencodeCommand",
        },
        -- 按键映射懒加载
        keys = {
            -- 主要功能快捷键
            {
                "<leader>oa",
                function()
                    local ok, opencode = pcall(require, "opencode")
                    if ok then
                        opencode.ask("@this: ", { submit = true })
                    else
                        vim.notify("opencode.nvim 未加载: " .. tostring(opencode), vim.log.levels.ERROR)
                    end
                end,
                desc = "询问 opencode（当前选择）",
                mode = { "n", "x" },
            },
            {
                "<leader>os",
                function()
                    local ok, opencode = pcall(require, "opencode")
                    if ok then
                        opencode.select()
                    else
                        vim.notify("opencode.nvim 未加载: " .. tostring(opencode), vim.log.levels.ERROR)
                    end
                end,
                desc = "选择 opencode 操作",
                mode = { "n", "x" },
            },
            {
                "<leader>ot",
                function()
                    local ok, opencode = pcall(require, "opencode")
                    if ok then
                        opencode.toggle()
                    else
                        vim.notify("opencode.nvim 未加载: " .. tostring(opencode), vim.log.levels.ERROR)
                    end
                end,
                desc = "切换 opencode",
                mode = { "n", "t" },
            },
            -- 操作符模式
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
                "<leader>ou",
                function()
                    require("opencode").command("session.half.page.up")
                end,
                desc = "向上滚动 opencode 会话",
                mode = "n",
            },
            {
                "<leader>od",
                function()
                    require("opencode").command("session.half.page.down")
                end,
                desc = "向下滚动 opencode 会话",
                mode = "n",
            },
            {
                "<leader>oi",
                function()
                    require("opencode").command("session.interrupt")
                end,
                desc = "中断 opencode 会话",
                mode = "n",
            },
        },
        -- 插件配置
        config = function()
            -- 配置 opencode.nvim
            -- 根据官方文档：https://github.com/NickvanDyke/opencode.nvim
            -- opencode.nvim 使用 vim.g.opencode_opts 进行配置
            ---@type opencode.Opts
            vim.g.opencode_opts = {
                -- Provider 配置
                -- opencode.nvim 会自动检测 CWD 中已运行的 opencode 实例
                -- 如果找不到已存在的实例，才会使用配置的 provider 启动新的实例
                provider = {
                    -- 可选值: "terminal", "snacks", "kitty", "wezterm", "tmux", 或自定义函数
                    -- 如果已经在终端运行了 opencode --port，插件会自动检测到，不会启动新的实例
                    enabled = "terminal", -- 作为后备选项，如果找不到已存在的实例则使用
                    -- terminal provider 配置
                    terminal = {
                        -- 终端命令
                        cmd = "opencode",
                        -- 启动参数（必须使用 --port 标志来暴露服务器）
                        args = { "--port", "0" }, -- 使用随机端口
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
                    -- blink_cmp_sources = { ... },
                },
            }

            -- opencode.nvim 需要 autoread 来重载编辑后的文件
            -- 已在 basic.lua 中设置，这里确保设置正确
            vim.o.autoread = true

            -- 验证插件是否加载成功（仅在开发时使用）
            -- local ok, opencode = pcall(require, "opencode")
            -- if ok then
            --     vim.notify("opencode.nvim 已加载", vim.log.levels.INFO)
            -- else
            --     vim.notify("opencode.nvim 加载失败: " .. tostring(opencode), vim.log.levels.ERROR)
            -- end

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

