-- L3MON4D3/LuaSnip

-- Snippet Engine for Neovim written in Lua.

-- https://github.com/L3MON4D3/LuaSnip

return {
    {
        -- Plug name
        "L3MON4D3/LuaSnip",
        -- follow latest release.
        -- Version to use from the repository.
        version = "2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
        -- install jsregexp (optional!).
        -- Build is executed when a plugin is installed or updated. Before running build
        build = (not jit.os:find("Windows"))
        and "echo 'NOTE: jsregexp is optional, so not a big deal if it fails to build'; make install_jsregexp"
      or "make install_jsregexp",
        -- A list of plugin names or plugin specs that should be loaded when the plugin loads.
        dependencies = {
            "rafamadriz/friendly-snippets",
            config = function()
                require("luasnip.loaders.from_vscode").lazy_load()
            end,
        },
        -- Opts is a table will be passed to the Plugin.config() function. Setting this value will imply Plugin.config()
        opts = {
            history = true,
            delete_check_events = "TextChanged",
        },
        -- Lazy-load on key mapping
        keys = {
            {
                "<tab>",
                function()
                    return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
                end,
                expr = true, silent = true, mode = "i",
            },
            { "<tab>", function() require("luasnip").jump(1) end, mode = "s" },
            { "<s-tab>", function() require("luasnip").jump(-1) end, mode = { "i", "s" } },
        },
    },
}