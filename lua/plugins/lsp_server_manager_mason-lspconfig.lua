-- mason-org/mason-lspconfig.nvim
-- mason.nvim 与 nvim-lspconfig 的桥梁，简化 LSP 服务器安装与配置
-- https://github.com/mason-org/mason-lspconfig.nvim

return {
    {
        -- 插件名称
        "mason-org/mason-lspconfig.nvim",
        -- 依赖项：确保 mason.nvim 和 nvim-lspconfig 首先加载
        dependencies = {
            "mason-org/mason.nvim",
            "neovim/nvim-lspconfig"
        },
        -- 在 VeryLazy 事件时加载
        event = "VeryLazy",
        -- 插件配置选项
        opts = {
            -- 安装与更新统一由 mason-tool-installer 接管（见 lsp_server_manager_mason.lua），
            -- 此处仅保留“新 server 缺失时自动安装”的兑底，不重复声明清单
            automatic_installation = true,
            -- 处理程序配置（使用新 API）
            -- lsp 启用与 on_attach 由 lsp_server_nvim-lspconfig.lua 统一处理
            handlers = {
                function() end,
            },
        },
    },
}
