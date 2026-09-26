-- mason-org/mason.nvim
-- 便携式包管理器，安装与管理 LSP、DAP、linter 与 formatter
-- https://github.com/mason-org/mason.nvim

return {
    {
        -- 插件名称
        "mason-org/mason.nvim",
        -- 依赖项：自动安装工具
        dependencies = {
            "WhoIsSethDaniel/mason-tool-installer.nvim",
        },
        -- 基于命令的懒加载
        cmd = "Mason",
        -- 基于按键映射的懒加载
        keys = {
            { "<leader>cm", "<cmd>Mason<cr>", desc = "打开 Mason 包管理器" },
            { "<leader>cM", "<cmd>MasonUpdate<cr>", desc = "更新 Mason 注册表" },
        },
        -- 插件安装或更新时执行的构建命令
        build = ":MasonUpdate", -- :MasonUpdate 更新注册表内容
        -- 插件配置函数（使用 config 而不是 opts，以便集成 mason-tool-installer）
        config = function()
            require("mason").setup({
            -- 用户界面配置
            ui = {
                -- 图标配置
                icons = {
                    package_installed = "✓",    -- 已安装包的图标
                    package_pending = "➜",      -- 待安装包的图标
                    package_uninstalled = "✗"   -- 未安装包的图标
                },
                -- 检查过期包的间隔（毫秒）
                check_outdated_packages_on_open = true,
                -- 窗口边框样式
                border = "rounded",
                -- 窗口宽度和高度
                width = 0.8,
                height = 0.9,
                -- 键位映射
                keymaps = {
                    -- 展开包详情
                    toggle_package_expand = "<CR>",
                    -- 安装包
                    install_package = "i",
                    -- 更新包
                    update_package = "u",
                    -- 检查包版本
                    check_package_version = "c",
                    -- 更新所有包
                    update_all_packages = "U",
                    -- 检查过期包
                    check_outdated_packages = "C",
                    -- 卸载包
                    uninstall_package = "X",
                    -- 取消安装
                    cancel_installation = "<C-c>",
                    -- 应用语言过滤器
                    apply_language_filter = "<C-f>",
                },
            },
            -- 安装根目录
            install_root_dir = vim.fn.stdpath("data") .. "/mason",
            -- 让 mason 所有 Python 包都走 uv tool install，速度 20×+
            pip = {
                -- 升级 pip（禁用，因为使用 uv）
                upgrade_pip = false,
            },
            -- 日志级别
            log_level = vim.log.levels.INFO,
            -- 最大并发安装数
            max_concurrent_installers = 4,
            -- GitHub 配置
            github = {
                -- 下载 URL 模板
                download_url_template = "https://github.com/%s/releases/download/%s/%s",
            },
            })

            -- 由 mason-tool-installer 安装与更新（Neovim 内 Mason，不走 uv/brew）。
            -- 无头补装用 :MasonToolsInstallSync，不要 MasonInstall 后立刻 qa!。
            -- 9 个 LSP：lua_ls/bashls/clangd/pyright/rust_analyzer/jsonls/yamlls/marksman + ruff-lsp
            -- 另有 conform/dap：black、stylua、debugpy、codelldb
            require("mason-tool-installer").setup({
                ensure_installed = {
                    -- LSP 服务器（run_on_start + auto_update 自动安装与更新）
                    "lua_ls",
                    "bashls",
                    "clangd",
                    "pyright",
                    "rust_analyzer",
                    "jsonls",
                    "yamlls",
                    "marksman",
                    "ruff-lsp",     -- Ruff Python 代码检查器和格式化工具
                    "black",        -- conform Python 格式化
                    "stylua",       -- conform Lua 格式化
                    "debugpy",      -- Python 调试器
                    "codelldb",     -- C/C++/Rust 调试器
                },
                auto_update = true,
                run_on_start = true,
            })
        end,
    },
}
