-- telescope
-- https://github.com/nvim-telescope/telescope.nvim

return {
    {
        -- 插件名称
        'nvim-telescope/telescope.nvim', 
        tag = "0.1.8", -- 使用最新稳定版本
        -- 当插件加载时应该加载的插件名称或插件规范列表
        dependencies = { 
            'nvim-lua/plenary.nvim',
            -- 可选：性能优化的原生排序器
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                build = 'make',
                cond = function()
                    return vim.fn.executable 'make' == 1
                end,
            },
        },
        cmd = "Telescope", -- 命令懒加载
        -- 按键映射懒加载
        keys = {
            { "<leader>ff", function() require('telescope.builtin').find_files() end, desc = "查找文件" },
            { "<leader>fg", function() require('telescope.builtin').live_grep() end, desc = "实时搜索" },
            { "<leader>fb", function() require('telescope.builtin').buffers() end, desc = "缓冲区列表" },
            { "<leader>fh", function() require('telescope.builtin').help_tags() end, desc = "帮助标签" },
            { "<leader>fr", function() require('telescope.builtin').oldfiles() end, desc = "最近文件" },
            { "<leader>fc", function() require('telescope.builtin').commands() end, desc = "命令列表" },
            { "<leader>fk", function() require('telescope.builtin').keymaps() end, desc = "键位映射" },
            { "<leader>fs", function() require('telescope.builtin').grep_string() end, desc = "搜索当前单词" },
            { "<leader>fd", function() require('telescope.builtin').diagnostics() end, desc = "诊断信息" },
            { "<leader>ft", function() require('telescope.builtin').treesitter() end, desc = "Treesitter 符号" },
            { "<leader>fm", function() require('telescope.builtin').marks() end, desc = "标记列表" },
            { "<leader>fj", function() require('telescope.builtin').jumplist() end, desc = "跳转列表" },
            { "<leader>fq", function() require('telescope.builtin').quickfix() end, desc = "快速修复列表" },
            { "<leader>fl", function() require('telescope.builtin').loclist() end, desc = "位置列表" },
            { "<leader>fv", function() require('telescope.builtin').vim_options() end, desc = "Vim 选项" },
            { "<leader>fp", function() require('telescope.builtin').planets() end, desc = "行星" },
            { "<leader>fz", function() require('telescope.builtin').current_buffer_fuzzy_find() end, desc = "当前缓冲区模糊搜索" },
            { "<leader>rs", function() require('telescope.builtin').resume() end, desc = "恢复上次搜索" },
            -- Git 相关搜索
            { "<leader>gf", function() require('telescope.builtin').git_files() end, desc = "Git 文件" },
            { "<leader>gc", function() require('telescope.builtin').git_commits() end, desc = "Git 提交" },
            { "<leader>gb", function() require('telescope.builtin').git_branches() end, desc = "Git 分支" },
            { "<leader>gs", function() require('telescope.builtin').git_status() end, desc = "Git 状态" },
            { "<leader>gt", function() require('telescope.builtin').git_stash() end, desc = "Git 暂存" },
            -- LSP 相关搜索
            { "<leader>lr", function() require('telescope.builtin').lsp_references() end, desc = "LSP 引用" },
            { "<leader>ld", function() require('telescope.builtin').lsp_definitions() end, desc = "LSP 定义" },
            { "<leader>li", function() require('telescope.builtin').lsp_implementations() end, desc = "LSP 实现" },
            { "<leader>lt", function() require('telescope.builtin').lsp_type_definitions() end, desc = "LSP 类型定义" },
            { "<leader>ls", function() require('telescope.builtin').lsp_document_symbols() end, desc = "文档符号" },
            { "<leader>lw", function() require('telescope.builtin').lsp_workspace_symbols() end, desc = "工作区符号" },
        },
        -- 配置选项
        config = function()
            local telescope = require('telescope')
            local actions = require('telescope.actions')
            
            telescope.setup({
                defaults = {
                    -- 默认配置
                    prompt_prefix = "🔍 ",
                    selection_caret = "➤ ",
                    path_display = { "truncate" },
                    file_ignore_patterns = {
                        "node_modules",
                        ".git/",
                        "dist/",
                        "build/",
                        "target/",
                        "*.lock",
                    },
                    -- 键位映射
                    mappings = {
                        i = {
                            ["<C-n>"] = actions.cycle_history_next,
                            ["<C-p>"] = actions.cycle_history_prev,
                            ["<C-i>"] = actions.move_selection_previous,
                            ["<C-k>"] = actions.move_selection_next,
                            ["<C-c>"] = actions.close,
                            ["<Down>"] = actions.move_selection_next,
                            ["<Up>"] = actions.move_selection_previous,
                            ["<CR>"] = actions.select_default,
                            ["<C-x>"] = actions.select_horizontal,
                            ["<C-v>"] = actions.select_vertical,
                            ["<C-t>"] = actions.select_tab,
                            ["<C-u>"] = actions.preview_scrolling_up,
                            ["<C-d>"] = actions.preview_scrolling_down,
                            ["<PageUp>"] = actions.results_scrolling_up,
                            ["<PageDown>"] = actions.results_scrolling_down,
                            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
                            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
                            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
                            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                            ["<C-l>"] = actions.complete_tag,
                            ["<C-h>"] = actions.which_key, -- 显示键位帮助
                        },
                        n = {
                            ["<esc>"] = actions.close,
                            ["<CR>"] = actions.select_default,
                            ["<C-x>"] = actions.select_horizontal,
                            ["<C-v>"] = actions.select_vertical,
                            ["<C-t>"] = actions.select_tab,
                            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
                            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
                            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
                            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                            ["j"] = actions.move_selection_next,
                            ["k"] = actions.move_selection_previous,
                            ["H"] = actions.move_to_top,
                            ["M"] = actions.move_to_middle,
                            ["L"] = actions.move_to_bottom,
                            ["<Down>"] = actions.move_selection_next,
                            ["<Up>"] = actions.move_selection_previous,
                            ["gg"] = actions.move_to_top,
                            ["G"] = actions.move_to_bottom,
                            ["<C-u>"] = actions.preview_scrolling_up,
                            ["<C-d>"] = actions.preview_scrolling_down,
                            ["<PageUp>"] = actions.results_scrolling_up,
                            ["<PageDown>"] = actions.results_scrolling_down,
                            ["?"] = actions.which_key,
                        },
                    },
                },
                pickers = {
                    -- 特定选择器的配置
                    find_files = {
                        -- 查找文件时显示隐藏文件
                        find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
                    },
                    live_grep = {
                        additional_args = function(opts)
                            return {"--hidden"}
                        end
                    },
                },
                extensions = {
                    -- 扩展配置
                    fzf = {
                        fuzzy = true,                    -- 启用模糊匹配
                        override_generic_sorter = true,  -- 覆盖通用排序器
                        override_file_sorter = true,     -- 覆盖文件排序器
                        case_mode = "smart_case",        -- 智能大小写
                    }
                },
            })
            
            -- 加载扩展
            pcall(require('telescope').load_extension, 'fzf')
        end,
    },
}
