-- williamboman/mason.nvim

-- Neovim 的便携式包管理器
-- 可在 Neovim 运行的任何地方运行
-- 轻松安装和管理 LSP 服务器、DAP 服务器、代码检查器和格式化工具

-- https://github.com/williamboman/mason.nvim

return {
    {
        -- 插件名称
        "williamboman/mason.nvim",
        -- 基于命令的懒加载
        cmd = "Mason",
        -- 基于按键映射的懒加载
        keys = { 
            { "<leader>cm", "<cmd>Mason<cr>", desc = "打开 Mason 包管理器" },
            { "<leader>cM", "<cmd>MasonUpdate<cr>", desc = "更新 Mason 注册表" },
        },
        -- 插件安装或更新时执行的构建命令
        build = ":MasonUpdate", -- :MasonUpdate 更新注册表内容
        -- 插件配置选项
        opts = {
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
            -- 包安装配置
            pip = {
                -- 升级 pip
                upgrade_pip = false,
                -- 安装参数
                install_args = {},
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
        },
    },
}