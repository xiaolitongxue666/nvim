-- mfussenegger/nvim-dap

-- Neovim 的调试适配器协议客户端实现

-- https://github.com/mfussenegger/nvim-dap

return {
    {
        -- 插件名称
        "mfussenegger/nvim-dap",
        -- 当插件加载时应该加载的插件名称或插件规范列表
        dependencies = {
            -- 调试器的精美 UI 界面
            {
                -- 依赖插件名称
                "rcarriga/nvim-dap-ui",
                -- 按键映射懒加载
                keys = {
                    { "<leader>du", function() require("dapui").toggle({ }) end, desc = "调试 UI" },
                    { "<leader>de", function() require("dapui").eval() end, desc = "表达式求值", mode = {"n", "v"} },
                },
                -- opts 是一个将传递给 Plugin.config() 函数的表。设置此值将暗示 Plugin.config()
                opts = {},
                -- config 在插件加载时执行
                config = function(_, opts)
                    local dap = require("dap")
                    local dapui = require("dapui")
                    dapui.setup(opts)
                    dap.listeners.after.event_initialized["dapui_config"] = function()
                        dapui.open({})
                    end
                    dap.listeners.before.event_terminated["dapui_config"] = function()
                        dapui.close({})
                    end
                    dap.listeners.before.event_exited["dapui_config"] = function()
                        dapui.close({})
                    end
                end,
            },

            -- 调试器的虚拟文本显示
            {
                -- 依赖插件名称
                "theHamsta/nvim-dap-virtual-text",
                -- opts 是一个将传递给 Plugin.config() 函数的表。设置此值将暗示 Plugin.config()
                opts = {},
            },

            -- which-key 集成
            {
                -- 依赖插件名称
                "folke/which-key.nvim",
                -- 这主要对 Neovim 发行版有用，允许在可能/可能不是用户插件一部分的插件上设置选项
                optional = true,
                -- opts 是一个将传递给 Plugin.config() 函数的表。设置此值将暗示 Plugin.config()
                opts = {
                    defaults = {
                        ["<leader>d"] = { name = "+调试" },
                        ["<leader>da"] = { name = "+适配器" },
                    },
                },
            },

            -- mason.nvim 集成
            {
                -- 依赖插件名称
                "jay-babu/mason-nvim-dap.nvim",
                -- 当插件加载时应该加载的插件名称或插件规范列表
                dependencies = "mason.nvim",
                -- 命令懒加载
                cmd = { "DapInstall", "DapUninstall" },
                -- opts 是一个将传递给 Plugin.config() 函数的表。设置此值将暗示 Plugin.config()
                opts = {
                    -- 尽最大努力使用合理的调试配置设置各种调试器
                    automatic_installation = true,

                    -- 您可以为处理程序提供额外的配置，
                    -- 有关更多信息，请参阅 mason-nvim-dap README
                    handlers = {},

                    -- 您需要检查是否已安装所需的组件
                    -- 在线查看，请不要问我如何安装它们 :)
                    ensure_installed = {
                        -- 更新此项以确保您拥有所需语言的调试器
                    },
                },
            },
        },

        -- 按键映射懒加载
        keys = {
            { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('断点条件: ')) end, desc = "条件断点" },
            { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "切换断点" },
            { "<leader>dc", function() require("dap").continue() end, desc = "继续执行" },
            { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "运行到光标" },
            { "<leader>dg", function() require("dap").goto_() end, desc = "跳转到行（不执行）" },
            { "<leader>di", function() require("dap").step_into() end, desc = "步入" },
            { "<leader>dj", function() require("dap").down() end, desc = "向下" },
            { "<leader>dk", function() require("dap").up() end, desc = "向上" },
            { "<leader>dl", function() require("dap").run_last() end, desc = "运行上次" },
            { "<leader>do", function() require("dap").step_out() end, desc = "步出" },
            { "<leader>dO", function() require("dap").step_over() end, desc = "步过" },
            { "<leader>dp", function() require("dap").pause() end, desc = "暂停" },
            { "<leader>dr", function() require("dap").repl.toggle() end, desc = "切换 REPL" },
            { "<leader>ds", function() require("dap").session() end, desc = "会话" },
            { "<leader>dt", function() require("dap").terminate() end, desc = "终止" },
            { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "小部件" },
        },

        -- 配置各种编程语言的调试适配器
        config = function()
            local dap = require("dap")
            
            -- LLDB 适配器配置（用于 C/C++/Rust）
            dap.adapters.lldb = {
                type = 'executable',
                command = '/usr/bin/lldb-vscode', -- 根据需要调整，必须是绝对路径
                name = "lldb"
            }
            
            -- C++ 调试配置
            dap.configurations.cpp = {
                {
                    name = "启动程序",
                    type = "lldb",
                    request = "launch",
                    program = function()
                        return vim.fn.input('可执行文件路径: ', vim.fn.getcwd() .. '/', 'file')
                    end,
                    cwd = '${workspaceFolder}',
                    stopOnEntry = false,
                    args = {},
                    runInTerminal = true,
                },
                {
                    name = "附加到进程",
                    type = "lldb",
                    request = "attach",
                    pid = function()
                        return vim.fn.input('进程 ID: ')
                    end,
                    args = {},
                },
            }
            
            -- Rust 调试配置
            dap.configurations.rust = {
                {
                    name = "启动 Rust 程序",
                    type = "lldb",
                    request = "launch",
                    program = function()
                        return vim.fn.input('可执行文件路径: ', vim.fn.getcwd() .. '/target/debug/', 'file')
                    end,
                    cwd = '${workspaceFolder}',
                    stopOnEntry = false,
                    args = {},
                    runInTerminal = true,
                    initCommands = function()
                        -- 查找 Rust 美化打印 Python 模块的位置
                        local rustc_sysroot = vim.fn.trim(vim.fn.system('rustc --print sysroot'))

                        local script_import = 'command script import "' .. rustc_sysroot .. '/lib/rustlib/etc/lldb_lookup.py"'
                        local commands_file = rustc_sysroot .. '/lib/rustlib/etc/lldb_commands'

                        local commands = {}
                        local file = io.open(commands_file, 'r')
                        if file then
                            for line in file:lines() do
                                table.insert(commands, line)
                            end
                            file:close()
                        end
                        table.insert(commands, 1, script_import)

                        return commands
                    end,
                },
            }

            -- C 语言使用与 C++ 相同的配置
            dap.configurations.c = dap.configurations.cpp
            
            -- Python 调试适配器配置
            dap.adapters.python = {
                type = 'executable',
                command = 'python',
                args = { '-m', 'debugpy.adapter' },
            }
            
            -- Python 调试配置
            dap.configurations.python = {
                {
                    type = 'python',
                    request = 'launch',
                    name = "启动 Python 文件",
                    program = "${file}",
                    pythonPath = function()
                        return '/usr/bin/python3'
                    end,
                },
            }
            
            -- Node.js 调试适配器配置
            dap.adapters.node2 = {
                type = 'executable',
                command = 'node',
                args = { vim.fn.stdpath("data") .. '/mason/packages/node-debug2-adapter/out/src/nodeDebug.js' },
            }
            
            -- JavaScript/TypeScript 调试配置
            dap.configurations.javascript = {
                {
                    name = "启动 Node.js",
                    type = "node2",
                    request = "launch",
                    program = "${file}",
                    cwd = vim.fn.getcwd(),
                    sourceMaps = true,
                    protocol = "inspector",
                    console = "integratedTerminal",
                },
            }
            
            -- TypeScript 使用与 JavaScript 相同的配置
            dap.configurations.typescript = dap.configurations.javascript
        end,
    },
}