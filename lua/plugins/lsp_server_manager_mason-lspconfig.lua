-- williamboman/mason-lspconfig.nvim

-- mason.nvim 的扩展，使 lspconfig 与 mason.nvim 更容易配合使用

-- https://github.com/williamboman/mason-lspconfig.nvim
-- https://github.com/williamboman/mason-lspconfig.nvim#available-lsp-servers

return {
    {
        -- 插件名称
        "williamboman/mason-lspconfig.nvim",
        -- 依赖项确保 mason.nvim 首先加载
        dependencies = { "williamboman/mason.nvim" },
        -- 插件加载时执行的配置函数
        config = function()
            -- 移除重复的 mason.setup() 调用
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls",
                    "bashls", 
                    "clangd",
                    "pyright",
                    "rust_analyzer",
                },
                automatic_installation = true,
            })
        end
    },
}
