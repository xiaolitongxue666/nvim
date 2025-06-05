-- lewis6991/gitsigns.nvim
-- Git 缓冲区集成插件，提供 Git 状态显示、hunk 操作、blame 等功能
-- 为 Neovim 缓冲区提供深度的 Git 集成支持
-- 需要 Neovim >= 0.9.0

-- 官方文档: https://github.com/lewis6991/gitsigns.nvim

return {
    {
        -- 插件名称
        "lewis6991/gitsigns.nvim",
        -- 在事件时延迟加载
        event = { "BufReadPre", "BufNewFile" },
        -- opts 是一个表，将传递给 Plugin.config() 函数。设置此值将隐含调用 Plugin.config()
        opts = {
            -- Git 状态标识符配置
            signs = {
                add = { text = "▎" },
                change = { text = "▎" },
                delete = { text = "" },
                topdelete = { text = "" },
                changedelete = { text = "▎" },
                untracked = { text = "▎" },
            },
            
            -- 暂存区状态标识符配置
            signs_staged = {
                add = { text = "▎" },
                change = { text = "▎" },
                delete = { text = "" },
                topdelete = { text = "" },
                changedelete = { text = "▎" },
                untracked = { text = "▎" },
            },
            
            -- 启用暂存区状态显示
            signs_staged_enable = true,
            
            -- 基本显示配置
            signcolumn = true,  -- 显示标识列
            numhl = false,      -- 不高亮行号
            linehl = false,     -- 不高亮整行
            word_diff = false,  -- 不启用单词级别的 diff
            
            -- 监控 Git 目录变化
            watch_gitdir = {
                follow_files = true
            },
            
            -- 自动附加到缓冲区
            auto_attach = true,
            attach_to_untracked = false,
            
            -- 当前行 blame 配置
            current_line_blame = false, -- 默认关闭，可通过命令切换
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = 'eol', -- 在行尾显示
                delay = 1000,
                ignore_whitespace = false,
                virt_text_priority = 100,
                use_focus = true,
            },
            current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
            
            -- 性能优化配置
            sign_priority = 6,
            update_debounce = 100,
            max_file_length = 40000, -- 超过此行数的文件将被禁用
            
            -- 预览窗口配置
            preview_config = {
                style = 'minimal',
                relative = 'cursor',
                row = 0,
                col = 1
            },
            -- 快捷键映射配置
            on_attach = function(buffer)
                local gs = package.loaded.gitsigns

                local function map(mode, l, r, desc)
                    vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
                end

                -- Hunk 导航
                map("n", "]h", function()
                    if vim.wo.diff then
                        vim.cmd.normal({']c', bang = true})
                    else
                        gs.nav_hunk('next')
                    end
                end, "Git: 下一个 Hunk")
                
                map("n", "[h", function()
                    if vim.wo.diff then
                        vim.cmd.normal({'[c', bang = true})
                    else
                        gs.nav_hunk('prev')
                    end
                end, "Git: 上一个 Hunk")

                -- Hunk 操作
                map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Git: 暂存 Hunk")
                map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Git: 重置 Hunk")
                map("n", "<leader>ghS", gs.stage_buffer, "Git: 暂存整个缓冲区")
                map("n", "<leader>ghu", gs.undo_stage_hunk, "Git: 撤销暂存 Hunk")
                map("n", "<leader>ghR", gs.reset_buffer, "Git: 重置整个缓冲区")
                map("n", "<leader>ghp", gs.preview_hunk, "Git: 预览 Hunk")
                map("n", "<leader>ghi", gs.preview_hunk_inline, "Git: 内联预览 Hunk")

                -- Blame 功能
                map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Git: 显示行 Blame")
                map("n", "<leader>ghtb", gs.toggle_current_line_blame, "Git: 切换当前行 Blame")
                map("n", "<leader>ghB", function() gs.blame() end, "Git: 显示文件 Blame")

                -- Diff 功能
                map("n", "<leader>ghd", gs.diffthis, "Git: Diff 当前文件")
                map("n", "<leader>ghD", function() gs.diffthis("~") end, "Git: Diff 当前文件 (HEAD~1)")

                -- 切换功能
                map("n", "<leader>ghts", gs.toggle_signs, "Git: 切换标识显示")
                map("n", "<leader>ghtn", gs.toggle_numhl, "Git: 切换行号高亮")
                map("n", "<leader>ghtl", gs.toggle_linehl, "Git: 切换行高亮")
                map("n", "<leader>ghtw", gs.toggle_word_diff, "Git: 切换单词 Diff")
                map("n", "<leader>ghtd", gs.toggle_deleted, "Git: 切换已删除行显示")

                -- 文本对象
                map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Git: 选择 Hunk")

                -- 快速列表
                map("n", "<leader>ghq", function() gs.setqflist('all') end, "Git: 所有 Hunks 到 Quickfix")
                map("n", "<leader>ghl", function() gs.setloclist() end, "Git: 当前缓冲区 Hunks 到 Location List")
            end,
        },
    },
}