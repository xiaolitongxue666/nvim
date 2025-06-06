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
    {
        -- 兼容性配置：如果 Neovim < 0.10，继续使用 neodev.nvim
        "folke/neodev.nvim",
        cond = function()
            return vim.fn.has("nvim-0.10") == 0
        end,
        ft = "lua",
        opts = {
            -- 库配置
            library = {
                enabled = true, -- 当未启用时，neodev 不会更改 LSP 服务器的任何设置
                -- 这些设置将用于您的 Neovim 配置目录
                runtime = true, -- 运行时路径
                types = true, -- vim.api、vim.treesitter、vim.lsp 等的完整签名、文档和补全
                plugins = true, -- packpath 中已安装的 opt 或 start 插件
                -- 您也可以指定要作为工作区库提供的插件列表
                -- plugins = { "nvim-treesitter", "plenary.nvim", "telescope.nvim" },
            },
            setup_jsonls = true, -- 配置 jsonls 为项目特定的 .luarc.json 文件提供补全
            -- 对于您的 Neovim 配置目录，将按原样使用 config.library 设置
            -- 对于插件目录（具有 /lua 目录的 root_dirs），config.library.plugins 将被禁用
            -- 对于任何其他目录，config.library.enabled 将设置为 false
            override = function(root_dir, options) end,
            -- 使用 lspconfig 时，Neodev 会自动设置您的 lua-language-server
            -- 如果禁用此选项，则必须在 lsp 启动选项中设置 {before_init=require("neodev.lsp").before_init}
            lspconfig = true,
            -- 更快，但需要最新版本的 lua-language-server
            -- 需要 lua-language-server >= 3.6.0
            pathStrict = true,
        },
    },
}