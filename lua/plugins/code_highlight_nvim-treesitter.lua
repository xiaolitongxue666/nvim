-- nvim-treesitter/nvim-treesitter

-- Nvim Treesitter configurations and abstraction layer

-- https://github.com/nvim-treesitter/nvim-treesitter

return {
    {
        -- Plug name
        "nvim-treesitter/nvim-treesitter",
        -- Build is executed when a plugin is installed or updated
        build = ":TSUpdate",
        -- Lazy-load on event
        event = { "BufReadPost", "BufNewFile" },
        -- Lazy-load on command
        cmd = { "TSUpdateSync" },
        -- Lazy-load on key mapping
        keys = {
            { "<c-space>", desc = "Increment selection" },
            { "<bs>", desc = "Decrement selection", mode = "x" },
        },
        -- Opts is a table will be passed to the Plugin.config() function. Setting this value will imply Plugin.config()
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
        -- Config is executed when the plugin loads.
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