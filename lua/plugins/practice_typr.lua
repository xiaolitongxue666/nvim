-- typr 打字练习插件
-- 提供美观的打字练习界面和统计仪表板
-- https://github.com/nvzone/typr

return {
    {
        -- 插件名称
        "nvzone/typr",
        -- 依赖插件
        dependencies = { "nvzone/volt" },
        -- 命令懒加载
        cmd = { "Typr", "TyprStats" },
        -- 插件配置选项（lazy.nvim 会自动处理 opts）
        opts = {},
    },
}

