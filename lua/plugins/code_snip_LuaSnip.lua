-- L3MON4D3/LuaSnip
-- Neovim 代码片段引擎
-- https://github.com/L3MON4D3/LuaSnip

return {
    {
        -- 插件名称
        "L3MON4D3/LuaSnip",
        -- 跟随最新发布版本
        -- 从仓库使用的版本
        version = "v2.*", -- 将 <CurrentMajor> 替换为最新发布的主版本号（最新版本的第一个数字）
        -- 构建 jsregexp，消除 checkhealth 警告（占位符转换能力）
        build = (vim.fn.executable("make") == 1) and "make install_jsregexp" or nil,
        -- 插件加载时需要加载的依赖插件列表
        dependencies = {
            "rafamadriz/friendly-snippets",
        },
        -- 插件配置
        config = function()
            local ls = require("luasnip")
            
            -- 加载 friendly-snippets
            require("luasnip.loaders.from_vscode").lazy_load()
            
            -- 配置选项
            ls.config.set_config({
                history = true,
                delete_check_events = "TextChanged",
                -- 更频繁地更新，查看 :h events 获取更多信息
                updateevents = "TextChanged,TextChangedI",
            })
        end,
        -- Tab/S-Tab 由 nvim-cmp 统一映射（避免与 cmp 冲突）
    },
}