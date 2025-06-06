-- jbyuki/one-small-step-for-vimkind

-- 🌙 Neovim 插件的调试适配器，用于调试在 Neovim 实例中运行的 Lua 代码

-- 官方文档：https://github.com/jbyuki/one-small-step-for-vimkind

return {
    -- 插件名称
    "jbyuki/one-small-step-for-vimkind",
    -- 依赖 nvim-dap 插件
    dependencies = {
        "mfussenegger/nvim-dap",
    },
    -- 延迟加载，仅在使用键位映射时加载
    lazy = true,
    -- 插件配置函数
    config = function()
        local dap = require("dap")
        
        -- 配置 Lua 调试适配器
        dap.adapters.nlua = function(callback, config)
            callback({
                type = "server",
                host = config.host or "127.0.0.1",
                port = config.port or 8086
            })
        end
        
        -- 配置 Lua 调试配置
        dap.configurations.lua = {
            {
                type = "nlua",
                request = "attach",
                name = "连接到正在运行的 Neovim 实例",
                -- 可选：指定主机和端口
                host = "127.0.0.1",
                port = 8086,
            },
        }
    end,
    -- 键位映射配置
    keys = {
        {
            "<leader>daL",
            function()
                require("osv").launch({ port = 8086 })
            end,
            desc = "启动 Lua 调试服务器",
        },
        {
            "<leader>dal",
            function()
                require("osv").run_this()
            end,
            desc = "调试当前 Lua 文件",
        },
    },
}

