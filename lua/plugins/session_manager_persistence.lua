-- folke/persistence.nvim
-- 自动保存与恢复编辑会话，支持多项目会话管理
-- https://github.com/folke/persistence.nvim

return {
    {
        "folke/persistence.nvim",
        -- 在启动时加载
        lazy = false,
        -- 按键映射时懒加载
        keys = {
            {
                "<leader>qs",
                function()
                    require("config.neo_tree_session").save()
                    require("persistence").save()
                end,
                desc = "保存会话",
            },
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
            -- 预保存：当前 persistence 版本不调用 opts.pre_save，由 PersistenceSavePre / <leader>qs 触发
            pre_save = function()
                require("config.neo_tree_session").save()
            end,
            -- 保存空会话
            save_empty = false,
        },
        -- 插件配置函数
        config = function(_, opts)
            require("persistence").setup(opts)
            require("config.neo_tree_session").setup_autocmds()

            -- 无头验收不写 session，避免覆盖用户「最后一次会话」及 sidecar
            vim.api.nvim_create_autocmd("VimEnter", {
                group = vim.api.nvim_create_augroup("persistence_headless_guard", { clear = true }),
                once = true,
                callback = function()
                    if vim.env.NVIM_HEADLESS_VALIDATE == "1" then
                        require("persistence").stop()
                    end
                end,
            })
        end,
    },
}
