-- windwp/nvim-autopairs
-- 一个功能强大的 Neovim 自动配对插件，支持多种字符
-- 用 Lua 编写的 Neovim 自动括号配对插件
-- 需要 Neovim 0.7 或更高版本

-- 官方文档: https://github.com/windwp/nvim-autopairs

return {
    {
        -- 插件名称
        "windwp/nvim-autopairs",
        -- 延迟加载事件 - 在插入模式时加载
        event = "InsertEnter",
        -- 插件加载时执行的配置
        config = function()
            -- 初始化 nvim-autopairs 插件
            require("nvim-autopairs").setup({
                -- 控制是否在附加到缓冲区时启用自动配对
                -- enabled = function(bufnr) return true end,
                
                -- 禁用的文件类型
                disable_filetype = { "TelescopePrompt", "spectre_panel" },
                
                -- 录制或执行宏时禁用
                disable_in_macro = true,
                
                -- 在可视块模式后插入时禁用
                disable_in_visualblock = false,
                
                -- 在替换模式下禁用
                disable_in_replace_mode = true,
                
                -- 忽略的下一个字符模式
                ignored_next_char = [=[[%w%%%'%[%"%.%`%$]]=],
                
                -- 启用向右移动
                enable_moveright = true,
                
                -- 在引号后添加括号对
                enable_afterquote = true,
                
                -- 检查同一行中的括号
                enable_check_bracket_line = true,
                
                -- 在引号中启用括号
                enable_bracket_in_quote = true,
                
                -- 触发缩写
                enable_abbr = false,
                
                -- 基本规则的撤销序列开关
                break_undo = true,
                
                -- 检查 treesitter
                check_ts = false,
                
                -- 映射 <CR> 键
                map_cr = true,
                
                -- 映射 <BS> 键
                map_bs = true,
                
                -- 映射 <C-h> 键删除配对
                map_c_h = false,
                
                -- 映射 <C-w> 键删除配对（如果可能）
                map_c_w = false,
            })
        end,
    },
}