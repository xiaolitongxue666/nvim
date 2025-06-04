-- rafamadriz/friendly-snippets

-- 为不同语言预配置的代码片段集合

-- https://github.com/rafamadriz/friendly-snippets

return {
    {
        "rafamadriz/friendly-snippets",
        config = function()
            require("luasnip.loaders.from_vscode").lazy_load()
        end,
    },
}