-- 简单的 Neovim 会话管理插件
-- 自动保存和恢复编辑会话，支持多项目会话管理

-- https://github.com/folke/persistence.nvim

return {
    {
        "folke/persistence.nvim",
        -- 在启动时加载
        lazy = false,
        -- 按键映射时懒加载
        keys = {
            { "<leader>qs", function() require("persistence").save() end, desc = "保存会话" },
            { "<leader>ql", function() require("persistence").load() end, desc = "加载会话" },
            { "<leader>qL", function() require("persistence").load({ last = true }) end, desc = "加载最后一个会话" },
            { "<leader>qd", function() require("persistence").stop() end, desc = "停止会话记录" },
        },
        -- 插件配置选项
        opts = {
            -- 会话保存目录
            dir = vim.fn.stdpath("state") .. "/sessions/",
            -- 会话选项
            options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" },
            -- 预保存钩子函数
            pre_save = nil,
            -- 保存空会话
            save_empty = false,
        },
        -- 插件配置函数
        config = function(_, opts)
            require("persistence").setup(opts)
            
            -- 自动加载会话
            local function auto_load_session()
                -- 只有在没有参数启动 Neovim 时才自动加载会话
                if vim.fn.argc(-1) == 0 then
                    require("persistence").load()
                end
            end
            
            -- 在 VimEnter 事件后自动加载会话
            vim.api.nvim_create_autocmd("VimEnter", {
                group = vim.api.nvim_create_augroup("persistence_auto_load", { clear = true }),
                callback = function()
                    -- 延迟执行以确保其他插件已加载
                    vim.defer_fn(auto_load_session, 200)
                end,
                nested = true,
            })
            
            -- 在会话加载完成后自动打开文件浏览器
            vim.api.nvim_create_autocmd("User", {
                pattern = "PersistenceLoadPost",
                group = vim.api.nvim_create_augroup("persistence_auto_tree", { clear = true }),
                callback = function()
                    -- 延迟打开文件浏览器，确保会话完全加载
                    vim.defer_fn(function()
                        require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
                    end, 200)
                end,
            })
            
            -- 在退出时自动保存会话
            vim.api.nvim_create_autocmd("VimLeavePre", {
                group = vim.api.nvim_create_augroup("persistence_auto_save", { clear = true }),
                callback = function()
                    -- 只有在有缓冲区时才保存会话
                    if #vim.api.nvim_list_bufs() > 1 then
                        require("persistence").save()
                    end
                end,
            })
        end,
    },
}
