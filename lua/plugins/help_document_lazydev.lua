-- folke/lazydev.nvim (替代 neodev.nvim)

-- 为 Neovim 配置和插件开发提供完整的 Lua API 签名帮助、文档和补全功能
-- 注意：neodev.nvim 已停止维护，官方推荐使用 lazydev.nvim 作为替代

-- 原项目：https://github.com/folke/neodev.nvim
-- 新项目：https://github.com/folke/lazydev.nvim

return {
    {
        -- 插件名称 (推荐的替代方案)
        "folke/lazydev.nvim",
        -- 仅在 Neovim >= 0.10 时启用
        cond = function()
            return vim.fn.has("nvim-0.10") == 1
        end,
        -- 文件类型触发
        ft = "lua",
        -- 配置选项
        opts = {
            -- 库配置
            library = {
                -- 当启用时，lazydev 会自动配置 lua_ls
                -- 可以是字符串数组或函数返回字符串数组
                -- 默认会加载所有插件的 lua 目录
                -- 设置为 false 禁用自动检测
                { path = "luvit-meta/library", words = { "vim%.uv" } },
            },
        },
    },
    {
        -- 为 vim.uv 提供类型定义
        "Bilal2453/luvit-meta",
        lazy = true,
    },
    -- neodev.nvim 已 archived；本配置要求 Neovim 0.11+，仅使用 lazydev.nvim
}