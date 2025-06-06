-- 美观的 Neovim 缓冲区标签页插件
-- 提供类似现代编辑器的标签页体验，支持图标、关闭按钮等功能

-- https://github.com/akinsho/bufferline.nvim

return {
    {
        "akinsho/bufferline.nvim",
        -- 在 VeryLazy 事件时加载
        event = "VeryLazy",
        -- 依赖项
        dependencies = "nvim-tree/nvim-web-devicons",
        -- 按键映射时懒加载
        keys = {
            { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "上一个缓冲区" },
            { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "下一个缓冲区" },
            { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "上一个缓冲区" },
            { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "下一个缓冲区" },
            { "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "固定缓冲区" },
            { "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", desc = "删除非固定缓冲区" },
            { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "删除其他缓冲区" },
            { "<leader>br", "<cmd>BufferLineCloseRight<cr>", desc = "删除右侧缓冲区" },
            { "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", desc = "删除左侧缓冲区" },
        },
        -- 插件配置选项
        opts = {
            options = {
                -- 模式："tabs" 或 "buffers"
                mode = "buffers",
                -- 主题样式
                themable = true,
                -- 数字显示
                numbers = "none",
                -- 关闭命令
                close_command = "bdelete! %d",
                right_mouse_command = "bdelete! %d",
                left_mouse_command = "buffer %d",
                middle_mouse_command = nil,
                -- 指示器
                indicator = {
                    icon = "▎",
                    style = "icon",
                },
                -- 缓冲区关闭图标
                buffer_close_icon = "",
                modified_icon = "●",
                close_icon = "",
                left_trunc_marker = "",
                right_trunc_marker = "",
                -- 名称格式化
                name_formatter = function(buf)
                    -- 移除文件扩展名
                    return vim.fn.fnamemodify(buf.name, ":t:r")
                end,
                -- 最大名称长度
                max_name_length = 18,
                max_prefix_length = 15,
                truncate_names = true,
                -- 标签大小
                tab_size = 21,
                -- 诊断
                diagnostics = "nvim_lsp",
                diagnostics_update_in_insert = false,
                diagnostics_indicator = function(count, level, diagnostics_dict, context)
                    local icon = level:match("error") and " " or " "
                    return " " .. icon .. count
                end,
                -- 偏移量（用于侧边栏）
                offsets = {
                    {
                        filetype = "neo-tree",
                        text = "文件浏览器",
                        text_align = "center",
                        separator = true,
                    },
                    {
                        filetype = "NvimTree",
                        text = "文件浏览器",
                        text_align = "center",
                        separator = true,
                    },
                },
                -- 颜色图标
                color_icons = true,
                -- 显示缓冲区图标
                show_buffer_icons = true,
                show_buffer_close_icons = true,
                show_close_icon = true,
                show_tab_indicators = true,
                show_duplicate_prefix = true,
                -- 持久化
                persist_buffer_sort = true,
                -- 分隔符样式
                separator_style = "slant",
                -- 强制删除终端
                enforce_regular_tabs = false,
                always_show_bufferline = true,
                -- 排序
                sort_by = "insert_after_current",
                -- 自定义过滤器
                custom_filter = function(buf_number, buf_numbers)
                    -- 过滤掉特定文件类型
                    local filetype = vim.bo[buf_number].filetype
                    if filetype == "qf" or filetype == "help" then
                        return false
                    end
                    return true
                end,
            },
            -- 高亮组配置
            highlights = {
                fill = {
                    bg = "#1e1e2e",
                },
                background = {
                    bg = "#313244",
                },
                buffer_selected = {
                    bold = true,
                    italic = false,
                },
                separator = {
                    fg = "#1e1e2e",
                    bg = "#313244",
                },
                separator_selected = {
                    fg = "#1e1e2e",
                },
                close_button = {
                    bg = "#313244",
                },
                close_button_selected = {
                    fg = "#f38ba8",
                },
            },
        },
        -- 插件配置函数
        config = function(_, opts)
            require("bufferline").setup(opts)
            
            -- 修复删除缓冲区后的行为
            vim.api.nvim_create_autocmd("BufDelete", {
                callback = function()
                    vim.schedule(function()
                        pcall(require("bufferline.api").set_offset, 0)
                    end)
                end,
            })
        end,
    },
}