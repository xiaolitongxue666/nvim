-- nvim-treesitter/nvim-treesitter
--
-- Nvim Treesitter 配置和抽象层
-- 提供语法高亮、缩进、增量选择等功能
--
-- 官方文档: https://github.com/nvim-treesitter/nvim-treesitter
-- 要求: Neovim 0.11.0+, tar, curl, tree-sitter-cli (0.26.1+), C 编译器
--
-- 注意: 此插件不支持懒加载，必须在启动时加载

return {
    {
        -- 插件名称
        "nvim-treesitter/nvim-treesitter",
        -- 指定 master 分支（官方要求）
        branch = 'master',
        -- 禁用懒加载，官方不支持懒加载
        lazy = false,
        -- 插件安装或更新时执行的构建命令
        -- 自动更新所有已安装的解析器到最新版本
        build = ":TSUpdate",
        -- Opts 是一个将传递给 Plugin.config() 函数的表。设置此值将隐含 Plugin.config()
        opts = {
            -- 安装目录（可选，默认使用 runtimepath）
            -- install_dir = vim.fn.stdpath('data') .. '/site',
            
            -- 语法高亮（由 Neovim 内置提供）
            highlight = {
                enable = true,
                -- 使用额外的正则表达式高亮（如果 treesitter 不支持）
                additional_vim_regex_highlighting = false,
            },
            
            -- 基于 treesitter 的缩进（实验性功能）
            indent = {
                enable = true,
                -- 禁用某些语言的缩进（如果出现问题）
                disable = {},
            },
            
            -- 自动安装解析器
            -- 注意: 如果遇到网络问题导致卡住，可以设置为 false，然后手动执行 :TSInstall <language>
            auto_install = false,
            
            -- 忽略解析器安装错误，避免启动时崩溃
            ignore_install = {},
            
            -- 确保安装的解析器列表
            -- 这些解析器会在插件安装时自动安装（如果 auto_install = true）
            ensure_installed = {
                "bash",
                "c",
                "html",
                "javascript",
                "jsdoc",
                "json",
                "lua",
                "luadoc",
                "luap",
                "markdown",
                "markdown_inline",
                "python",
                "query",
                "regex",
                "tsx",
                "typescript",
                "vim",
                -- "vimdoc",  -- 已禁用：编译失败，如需要可取消注释
                "yaml",
            },
            
            -- 增量选择功能
            -- 允许逐步扩展或缩小文本选择范围
            incremental_selection = {
                enable = true,
                keymaps = {
                    -- 初始化选择（开始增量选择）
                    init_selection = "<C-space>",
                    -- 扩展选择到下一个节点
                    node_incremental = "<C-space>",
                    -- 扩展选择到下一个作用域（已禁用）
                    scope_incremental = false,
                    -- 缩小选择范围
                    node_decremental = "<bs>",
                },
            },
        },
        -- 插件加载时执行的配置函数
        config = function(_, opts)
            -- 去重 ensure_installed 列表，避免重复安装
            if type(opts.ensure_installed) == "table" then
                ---@type table<string, boolean>
                local added = {}
                opts.ensure_installed = vim.tbl_filter(function(lang)
                    if added[lang] then
                        return false
                    end
                    added[lang] = true
                    return true
                end, opts.ensure_installed)
            end
            
            -- 设置 treesitter 配置，使用 pcall 捕获错误
            local ok, treesitter = pcall(require, "nvim-treesitter.configs")
            if ok then
                treesitter.setup(opts)
            else
                vim.notify("nvim-treesitter 配置失败: " .. tostring(treesitter), vim.log.levels.ERROR)
            end
        end,
    },
}