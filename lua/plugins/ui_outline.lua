-- outline.nvim
-- 代码大纲侧边栏，支持 LSP 和 Tree-sitter
-- https://github.com/hedyhli/outline.nvim

return {
    {
        -- 插件名称
        "hedyhli/outline.nvim",
        -- 依赖项
        dependencies = {
            "neovim/nvim-lspconfig", -- 确保 LSP 支持
            "nvim-treesitter/nvim-treesitter", -- 可选，用于 Tree-sitter 支持
            "onsails/lspkind.nvim", -- 图标支持
        },
        -- 在读取文件后懒加载
        event = "BufReadPost",
        -- 命令懒加载
        cmd = {
            "Outline",
            "OutlineOpen",
            "OutlineClose",
            "OutlineFocus",
        },
        -- 键位映射
                        keys = {
                    {
                        "<leader>o",
                        function()
                            -- 激进清理所有outline缓冲区
                            local buffers = vim.api.nvim_list_bufs()
                            for _, buf in ipairs(buffers) do
                                local bufname = vim.api.nvim_buf_get_name(buf)
                                local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
                                local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
                                
                                if (bufname:match("^outline://") or filetype == "outline") and buftype == "nofile" then
                                    vim.api.nvim_buf_delete(buf, { force = true })
                                end
                            end
                            
                            -- 检查是否已经有outline窗口
                            local outline_win = nil
                            for _, win in ipairs(vim.api.nvim_list_wins()) do
                                local buf = vim.api.nvim_win_get_buf(win)
                                local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
                                if filetype == "outline" then
                                    outline_win = win
                                    break
                                end
                            end
                            
                            if outline_win then
                                -- 如果存在，关闭它
                                vim.api.nvim_win_close(outline_win, true)
                            else
                                -- 如果不存在，打开它
                                vim.cmd("Outline")
                            end
                        end,
                        desc = "切换代码大纲",
                    },
                    {
                        "<leader>O",
                        function()
                            -- 强制关闭所有outline窗口
                            for _, win in ipairs(vim.api.nvim_list_wins()) do
                                local buf = vim.api.nvim_win_get_buf(win)
                                local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
                                if filetype == "outline" then
                                    vim.api.nvim_win_close(win, true)
                                end
                            end
                            
                            -- 激进清理所有outline缓冲区
                            local buffers = vim.api.nvim_list_bufs()
                            for _, buf in ipairs(buffers) do
                                local bufname = vim.api.nvim_buf_get_name(buf)
                                local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
                                local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
                                
                                if (bufname:match("^outline://") or filetype == "outline") and buftype == "nofile" then
                                    vim.api.nvim_buf_delete(buf, { force = true })
                                end
                            end
                            
                            -- 延迟打开，确保清理完成
                            vim.defer_fn(function()
                                vim.cmd("Outline")
                            end, 50)
                        end,
                        desc = "打开代码大纲",
                    },
                },
        -- 插件配置选项
        opts = {
            -- 大纲窗口配置
            outline_window = {
                -- 窗口宽度
                width = 15,
                -- 窗口位置
                position = "right",
                -- 显示光标行
                show_cursorline = true,
                -- 显示相对行号
                show_relative_numbers = true,
                -- 显示行号
                show_lineno = true,
                -- 窗口高亮配置
                winhl = "Normal:Normal,CursorLine:Visual,LineNr:LineNr",
                -- 自动关闭
                auto_close = false,
                -- 自动聚焦
                auto_focus = false,
                -- 保持打开
                keep_open = true,
            },
            -- 预览窗口配置
            preview_window = {
                -- 启用预览窗口
                auto_preview = false,
                -- 选中时打开预览
                open_on_select = true,
                -- 预览窗口宽度
                width = 50,
                -- 预览窗口高度
                height = 20,
                -- 预览窗口位置
                position = "right",
                -- 预览窗口边框
                border = "rounded",
                -- 预览窗口高亮
                winhl = "Normal:Normal,CursorLine:Visual",
            },
            -- 符号配置
            symbols = {
                -- 图标源
                icon_source = "lspkind",
            },
            -- 键位映射配置
            keymaps = {
                -- 跳转到位置
                goto_location = "<CR>",
                -- 预览位置
                peek_location = "o",
                -- 切换预览
                toggle_preview = "<C-p>",
                -- 折叠切换
                fold_toggle = "za",
                -- 折叠所有
                fold_all = "zM",
                -- 展开所有
                unfold_all = "zR",
                -- 关闭
                close = "q",
            },



        },
        -- 插件配置函数
        config = function(_, opts)
            -- 配置 outline
            require("outline").setup(opts)
            
            -- 激进的缓冲区清理函数
            local function aggressive_cleanup_outline()
                local buffers = vim.api.nvim_list_bufs()
                for _, buf in ipairs(buffers) do
                    local bufname = vim.api.nvim_buf_get_name(buf)
                    local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
                    local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
                    
                    -- 清理所有 outline 相关缓冲区，不管是否有窗口在使用
                    if (bufname:match("^outline://") or filetype == "outline") and buftype == "nofile" then
                        vim.api.nvim_buf_delete(buf, { force = true })
                    end
                end
            end
            
            -- 在启动时清理
            vim.api.nvim_create_autocmd("VimEnter", {
                group = vim.api.nvim_create_augroup("outline_cleanup", { clear = true }),
                callback = aggressive_cleanup_outline,
                once = true,
            })
            
            -- 在退出时清理
            vim.api.nvim_create_autocmd("VimLeavePre", {
                group = vim.api.nvim_create_augroup("outline_cleanup_exit", { clear = true }),
                callback = aggressive_cleanup_outline,
            })
            
            -- 在BufDelete事件时清理
            vim.api.nvim_create_autocmd("BufDelete", {
                group = vim.api.nvim_create_augroup("outline_cleanup_buf", { clear = true }),
                callback = function(event)
                    local bufname = vim.api.nvim_buf_get_name(event.buf)
                    if bufname:match("^outline://") then
                        aggressive_cleanup_outline()
                    end
                end,
            })
            
            -- 在WinClosed事件时清理
            vim.api.nvim_create_autocmd("WinClosed", {
                group = vim.api.nvim_create_augroup("outline_cleanup_win", { clear = true }),
                callback = function(event)
                    -- 延迟清理，确保窗口完全关闭
                    vim.defer_fn(aggressive_cleanup_outline, 100)
                end,
            })
            
            -- 在BufLeave事件时清理（当离开outline缓冲区时）
            vim.api.nvim_create_autocmd("BufLeave", {
                group = vim.api.nvim_create_augroup("outline_cleanup_leave", { clear = true }),
                callback = function(event)
                    local bufname = vim.api.nvim_buf_get_name(event.buf)
                    local filetype = vim.api.nvim_buf_get_option(event.buf, "filetype")
                    if bufname:match("^outline://") or filetype == "outline" then
                        vim.defer_fn(aggressive_cleanup_outline, 50)
                    end
                end,
            })
            
            -- 在TabLeave事件时清理
            vim.api.nvim_create_autocmd("TabLeave", {
                group = vim.api.nvim_create_augroup("outline_cleanup_tab", { clear = true }),
                callback = function()
                    vim.defer_fn(aggressive_cleanup_outline, 50)
                end,
            })
        end,
    },
}
