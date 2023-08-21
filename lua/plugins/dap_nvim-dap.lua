-- mfussenegger/nvim-dap

-- Debug Adapter Protocol client implementation for Neovim

-- https://github.com/mfussenegger/nvim-dap

return {
    {
        -- Plug name
        "mfussenegger/nvim-dap",
        -- A list of plugin names or plugin specs that should be loaded when the plugin loads.
        dependencies = {
            -- fancy UI for the debugger
            {
                -- Dependency plug name
                "rcarriga/nvim-dap-ui",
                -- Lazy-load on key mapping
                keys = {
                    { "<leader>du", function() require("dapui").toggle({ }) end, desc = "Dap UI" },
                    { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
                },
                -- Opts is a table will be passed to the Plugin.config() function. Setting this value will imply Plugin.config()
                opts = {},
                -- Config is executed when the plugin loads.
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

            -- virtual text for the debugger
            {
                -- Dependency plug name
                "theHamsta/nvim-dap-virtual-text",
                -- Opts is a table will be passed to the Plugin.config() function. Setting this value will imply Plugin.config()
                opts = {},
            },

            -- which key integration
            {
                -- Dependency plug name
                "folke/which-key.nvim",
                -- This is mainly useful for Neovim distros, to allow setting options on plugins that may/may not be part of the user's plugins
                optional = true,
                -- Opts is a table will be passed to the Plugin.config() function. Setting this value will imply Plugin.config()
                opts = {
                    defaults = {
                        ["<leader>d"] = { name = "+debug" },
                        ["<leader>da"] = { name = "+adapters" },
                    },
                },
            },

            -- mason.nvim integration
            {
                -- Dependency plug name
                "jay-babu/mason-nvim-dap.nvim",
                -- A list of plugin names or plugin specs that should be loaded when the plugin loads.
                dependencies = "mason.nvim",
                -- Lazy-load on command
                cmd = { "DapInstall", "DapUninstall" },
                -- Opts is a table will be passed to the Plugin.config() function. Setting this value will imply Plugin.config()
                opts = {
                    -- Makes a best effort to setup the various debuggers with
                    -- reasonable debug configurations
                    automatic_installation = true,

                    -- You can provide additional configuration to the handlers,
                    -- see mason-nvim-dap README for more information
                    handlers = {},

                    -- You'll need to check that you have the required things installed
                    -- online, please don't ask me how to install them :)
                    ensure_installed = {
                        -- Update this to ensure that you have the debuggers for the langs you want
                    },
                },
            },
        },

        -- Lazy-load on key mapping
        keys = {
            { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
            { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
            { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
            { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
            { "<leader>dg", function() require("dap").goto_() end, desc = "Go to line (no execute)" },
            { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
            { "<leader>dj", function() require("dap").down() end, desc = "Down" },
            { "<leader>dk", function() require("dap").up() end, desc = "Up" },
            { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
            { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
            { "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
            { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
            { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
            { "<leader>ds", function() require("dap").session() end, desc = "Session" },
            { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
            { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
        },

        ---- Config languages
        config = function()
            local dap = require("dap")
            dap.adapters.lldb = {
                type = 'executable',
                command = '/usr/bin/lldb-vscode', -- adjust as needed, must be absolute path
                name = "lldb"
            }
            dap.configurations.cpp = {
                {
                    name = "Launch",
                    type = "lldb",
                    request = "launch",
                    program = function()
                        return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
                    end,
                    cwd = '${workspaceFolder}',
                    stopOnEntry = false,
                    args = {},
                    runInTerminal = true,
                },
            }
            dap.configurations.rust = {
                {
                    -- ... the previous config goes here ...,
                    initCommands = function()
                        -- Find out where to look for the pretty printer Python module
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
                    -- ...,
                }
            }

            dap.configurations.c = dap.configurations.cpp
            dap.configurations.rust = dap.configurations.cpp
        end,
    },
}