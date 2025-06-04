-- nvim-treesitter/nvim-treesitter

-- Nvim Treesitter 配置和抽象层

-- https://github.com/nvim-treesitter/nvim-treesitter

return {
    {
        -- 插件名称
        "nvim-treesitter/nvim-treesitter",
        -- 插件安装或更新时执行的构建命令
        build = ":TSUpdate",
        -- 基于事件的懒加载
        event = { "BufReadPost", "BufNewFile" },
        -- 基于命令的懒加载
        cmd = { "TSUpdateSync" },
        -- 基于按键映射的懒加载
        keys = {
            { "<c-space>", desc = "Increment selection" },
            { "<bs>", desc = "Decrement selection", mode = "x" },
        },
        -- Opts 是一个将传递给 Plugin.config() 函数的表。设置此值将隐含 Plugin.config()
        opts = {
            highlight = { enable = true },
            indent = { enable = true },
            ensure_installed = {
                "bash",
                "c",
                "html",
                "javascript",
                "jsdoc",
                "json",
                "lua",
                "luadoc",
                "luap",
                "markdown",
                "markdown_inline",
                "python",
                "query",
                "regex",
                "tsx",
                "typescript",
                "vim",
                "vimdoc",
                "yaml",
            },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<C-space>",
                    node_incremental = "<C-space>",
                    scope_incremental = false,
                    node_decremental = "<bs>",
                },
            },
        },
        -- 插件加载时执行的配置函数
        config = function(_, opts)
            if type(opts.ensure_installed) == "table" then
                ---@type table<string, boolean>
                local added = {}
                opts.ensure_installed = vim.tbl_filter(function(lang)
                    if added[lang] then
                        return false
                    end
                    added[lang] = true
                    return true
                end, opts.ensure_installed)
            end
            require("nvim-treesitter.configs").setup(opts)
        end,
    },
}