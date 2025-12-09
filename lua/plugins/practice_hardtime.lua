-- hardtime.nvim 习惯培养插件
-- 帮助培养良好的 Vim 操作习惯，阻止重复按键并提供高效操作提示
-- https://github.com/m4xshen/hardtime.nvim

return {
    {
        -- 插件名称
        "m4xshen/hardtime.nvim",
        -- 立即加载（需要拦截按键事件）
        lazy = false,
        -- 依赖插件
        dependencies = { "MunifTanjim/nui.nvim" },
        -- 插件配置选项（lazy.nvim 会自动处理 opts）
        opts = {
            -- 最大时间窗口（毫秒），在此时间内重复按键会被计数
            max_time = 1000,
            -- 最大重复次数，超过此次数会被阻止或提示
            max_count = 3,
            -- 禁用鼠标支持
            disable_mouse = true,
            -- 启用提示消息，建议使用更高效的 Vim 操作
            hint = true,
            -- 启用通知消息，显示被限制或禁用的按键
            notification = true,
            -- 通知显示时间（毫秒），设置为 false 则永不超时
            timeout = 3000,
            -- 允许不同按键重置计数
            allow_different_key = true,
            -- 默认启用插件
            enabled = true,
            -- 限制的按键（针对 ikjl 键位布局）
            -- 注意：本配置使用 ikjl 布局（i=上，k=下，j=左，l=右）
            restricted_keys = {
                ["i"] = { "n", "v" }, -- 限制 i（上移）
                ["k"] = { "n", "v" }, -- 限制 k（下移）
                ["j"] = { "n", "v" }, -- 限制 j（左移）
                ["l"] = { "n", "v" }, -- 限制 l（右移）
                -- 禁用对原始 hjkl 的限制（因为已重映射为其他功能）
                ["h"] = false,
            },
            -- 禁用的按键（完全禁用，无法使用）
            disabled_keys = {
                ["<Up>"] = { "n", "v" },    -- 禁用上方向键
                ["<Down>"] = { "n", "v" },  -- 禁用下方向键
                ["<Left>"] = { "n", "v" },  -- 禁用左方向键
                ["<Right>"] = { "n", "v" }, -- 禁用右方向键
            },
            -- 限制模式："block"（阻止）或 "hint"（仅提示）
            restriction_mode = "block",
            -- 禁用某些文件类型（可根据需要添加）
            disabled_filetypes = {
                -- 示例：["typr"] = false, -- 在 typr 文件类型中启用 Hardtime
            },
        },
    },
}

