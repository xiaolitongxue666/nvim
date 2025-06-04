-- rcarriga/nvim-notify

-- NeoVim 的一个精美、可配置的通知管理器

-- https://github.com/rcarriga/nvim-notify

return {
    {
        -- 插件名称
        "rcarriga/nvim-notify",
        -- 在按键映射时懒加载
        keys = {
            {
                "<leader>un",
                function()
                    require("notify").dismiss({ silent = true, pending = true })
                end,
                desc = "关闭所有通知",
            },
        },
        -- Opts 是一个将传递给 Plugin.config() 函数的表。设置此值将隐含 Plugin.config()
        opts = {
            timeout = 3000,
            max_height = function()
                return math.floor(vim.o.lines * 0.75)
            end,
            max_width = function()
                return math.floor(vim.o.columns * 0.75)
            end,
        },
        -- Init 函数总是在启动时执行
        init = function()
            vim.notify = require("notify")
        end,
    },
}