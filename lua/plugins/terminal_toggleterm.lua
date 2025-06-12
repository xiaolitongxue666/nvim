-- https://github.com/akinsho/toggleterm.nvim
-- 终端管理插件：支持多个终端实例的切换和管理

return {
    {
        -- 插件名称
        "akinsho/toggleterm.nvim",
        version = "*", -- 使用最新稳定版本
        -- 在事件时懒加载
        event = "VeryLazy",
        -- 命令懒加载
        cmd = {
            "ToggleTerm",
            "TermExec",
            "ToggleTermToggleAll",
            "ToggleTermSendCurrentLine",
            "ToggleTermSendVisualLines",
            "ToggleTermSendVisualSelection",
        },
        -- 按键映射懒加载
        keys = {
            -- 主要终端快捷键
            { "<leader>/", "<cmd>ToggleTerm<cr>", desc = "切换终端", mode = { "n", "t" } },
            { "<C-`>", "<cmd>ToggleTerm<cr>", desc = "切换终端" },
            -- 其他终端类型
            { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "浮动终端" },
            { "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "水平终端" },
            { "<leader>tv", "<cmd>ToggleTerm direction=vertical size=80<cr>", desc = "垂直终端" },
            { "<leader>ta", "<cmd>ToggleTermToggleAll<cr>", desc = "切换所有终端" },
            -- 预定义终端快捷键
            { "<leader>tg", "<cmd>lua _LAZYGIT_TOGGLE()<cr>", desc = "Lazygit" },
            { "<leader>tn", "<cmd>lua _NODE_TOGGLE()<cr>", desc = "Node REPL" },
            { "<leader>tp", "<cmd>lua _PYTHON_TOGGLE()<cr>", desc = "Python REPL" },
            { "<leader>tr", "<cmd>lua _HTOP_TOGGLE()<cr>", desc = "Htop" },
        },
        -- 插件配置
        config = function()
            local toggleterm = require("toggleterm")
            
            -- 基础配置
            toggleterm.setup({
                -- 终端大小配置
                size = function(term)
                    if term.direction == "horizontal" then
                        return 15
                    elseif term.direction == "vertical" then
                        return vim.o.columns * 0.4
                    end
                end,
                -- 打开终端的快捷键（可以在普通模式、插入模式和终端模式使用）
                open_mapping = [[<leader>/]],
                -- 隐藏行号
                hide_numbers = true,
                -- 着色文件类型
                shade_filetypes = {},
                -- 自动改变目录
                autochdir = false,
                -- 着色终端
                shade_terminals = true,
                -- 着色因子（1-3，数字越大越暗）
                shading_factor = 2,
                -- 插入模式启动
                start_in_insert = true,
                -- 在插入模式下启用映射
                insert_mappings = true,
                -- 在终端模式下启用映射
                terminal_mappings = true,
                -- 持久化大小
                persist_size = true,
                -- 持久化模式
                persist_mode = true,
                -- 默认方向：'vertical' | 'horizontal' | 'tab' | 'float'
                direction = "horizontal",
                -- 退出时关闭
                close_on_exit = true,
                -- 使用的 shell
                shell = vim.o.shell,
                -- 自动滚动到底部
                auto_scroll = true,
                -- 浮动窗口配置
                float_opts = {
                    -- 边框样式：'single' | 'double' | 'shadow' | 'curved' | ... 其他选项见 :h nvim_open_win()
                    border = "curved",
                    -- 窗口宽度和高度（0-1 之间的浮点数或绝对值）
                    width = 120,
                    height = 30,
                    -- 窗口透明度（0-100）
                    winblend = 3,
                    -- 高亮组配置
                    highlights = {
                        border = "Normal",
                        background = "Normal",
                    },
                },
                -- 水平分割窗口配置
                horizontal_opts = {
                    border = "curved",
                },
                -- 垂直分割窗口配置
                vertical_opts = {
                    border = "curved",
                },
                -- 标签页配置
                tab_opts = {
                    border = "curved",
                },
                -- 窗口栏配置（实验性功能，仅限 Nightly 版本）
                winbar = {
                    enabled = false,
                    name_formatter = function(term)
                        return term.name
                    end
                },
            })
            
            -- 设置终端模式下的键位映射
            function _G.set_terminal_keymaps()
                local opts = { buffer = 0 }
                -- 终端切换（<leader>/ 关闭终端并回到之前窗口）
                vim.keymap.set('t', '<leader>/', '<cmd>ToggleTerm<cr>', opts)
                -- 退出终端模式但不关闭终端
                vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
                vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
                -- 窗口导航
                vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
                vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
                vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
                vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
                -- 调整窗口大小
                vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
            end
            
            -- 自动命令：在终端打开时设置键位映射
            vim.cmd('autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()')
            
            -- 预定义终端实例
            local Terminal = require('toggleterm.terminal').Terminal
            
            -- Lazygit 终端
            local lazygit = Terminal:new({
                cmd = "lazygit",
                dir = "git_dir",
                direction = "float",
                float_opts = {
                    border = "double",
                },
                -- 当终端进程退出时的回调函数
                on_open = function(term)
                    vim.cmd("startinsert!")
                    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
                end,
                on_close = function(term)
                    vim.cmd("startinsert!")
                end,
            })
            
            function _LAZYGIT_TOGGLE()
                lazygit:toggle()
            end
            
            -- Node REPL 终端
            local node = Terminal:new({
                cmd = "node",
                direction = "horizontal",
                size = 15,
            })
            
            function _NODE_TOGGLE()
                node:toggle()
            end
            
            -- Python REPL 终端
            local python = Terminal:new({
                cmd = "python3",
                direction = "horizontal",
                size = 15,
            })
            
            function _PYTHON_TOGGLE()
                python:toggle()
            end
            
            -- Htop 系统监控终端
            local htop = Terminal:new({
                cmd = "htop",
                direction = "float",
                float_opts = {
                    border = "double",
                    width = function()
                        return math.floor(vim.o.columns * 0.9)
                    end,
                    height = function()
                        return math.floor(vim.o.lines * 0.9)
                    end,
                },
            })
            
            function _HTOP_TOGGLE()
                htop:toggle()
            end
            
            -- 发送当前行到终端
            function _G.send_current_line_to_terminal()
                local line = vim.api.nvim_get_current_line()
                require('toggleterm').send_lines_to_terminal("single_line", true, { args = vim.v.count })
            end
            
            -- 发送选中内容到终端
            function _G.send_visual_selection_to_terminal()
                require('toggleterm').send_lines_to_terminal("visual_selection", true, { args = vim.v.count })
            end
            
            -- 额外的键位映射
            vim.keymap.set('n', '<leader>ts', '<cmd>lua send_current_line_to_terminal()<cr>', { desc = "发送当前行到终端" })
            vim.keymap.set('v', '<leader>ts', '<cmd>lua send_visual_selection_to_terminal()<cr>', { desc = "发送选中内容到终端" })
            
            -- 全局快捷键映射
            vim.keymap.set('n', '<leader>/', '<cmd>ToggleTerm<cr>', { desc = "切换终端" })
            vim.keymap.set('i', '<leader>/', '<esc><cmd>ToggleTerm<cr>', { desc = "切换终端" })
        end,
    },
}