-- williamboman/mason.nvim

-- Neovim 的便携式包管理器
-- 可在 Neovim 运行的任何地方运行。
-- 轻松安装和管理 LSP 服务器、DAP 服务器、代码检查器和格式化工具

-- https://github.com/williamboman/mason.nvim

return {
    {
        -- 插件名称
        "williamboman/mason.nvim",
        -- 基于命令的懒加载
        cmd = "Mason",
        -- 基于按键映射的懒加载
        keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
        -- 插件安装或更新时执行的构建命令
        build = ":MasonUpdate", -- :MasonUpdate 更新注册表内容
        -- Opts 是一个将传递给 Plugin.config() 函数的表。设置此值将隐含 Plugin.config()
        opts = {
            ui = {
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗"
                }
            }
        },
        -- 插件加载时执行的配置函数
        config = function(_, opts)
            require("mason").setup(opts)
        end,
    },
}