-- 基于 mini.starter 的启动页面配置
-- 替代 alpha-nvim，提供快速灵活的启动界面
-- https://github.com/echasnovski/mini.starter

return {
    -- 插件名称
    "echasnovski/mini.starter",
    -- 版本控制，使用最新版本
    version = false,
    -- 立即加载，确保启动菜单优先显示
    lazy = false,
    -- 插件配置
    config = function()
        -- 导入 mini.starter 模块
        local starter = require("mini.starter")
        
        -- 定义 ASCII logo
        local logo = [[
 __
/\ \
\ \ \         __    ___     ___
 \ \ \  __  /'__`\ / __`\ /' _ `\
  \ \ \L\ \/\  __//\ \L\ \/\ \/\ \
   \ \____/\ \____\ \____/\ \_\ \_\
    \/___/  \/____/\/___/  \/_/\/_/
        ]]
        
        -- 定义启动项目
        local items = {
            -- 查找文件
            {
                action = "Telescope find_files",
                name = "f Find file",
                section = "文件操作"
            },
            -- 新建文件
            {
                action = "ene | startinsert",
                name = "n New file",
                section = "文件操作"
            },
            -- 最近文件
            {
                action = "Telescope oldfiles",
                name = "r Recent files",
                section = "文件操作"
            },
            -- 文本搜索
            {
                action = "Telescope live_grep",
                name = "g Find text",
                section = "搜索功能"
            },
            -- 配置文件
            {
                action = "e $MYVIMRC",
                name = "c Config",
                section = "配置管理"
            },
            -- 恢复会话
            {
                action = "lua require('persistence').load()",
                name = "s Restore Session",
                section = "会话管理"
            },
            -- 恢复最后一个会话
            {
                action = "lua require('persistence').load({ last = true })",
                name = "S Restore Last Session",
                section = "会话管理"
            },
            -- Lazy 插件管理
            {
                action = "Lazy",
                name = "l Lazy",
                section = "插件管理"
            },
            -- 退出
            {
                action = "qa",
                name = "q Quit",
                section = "系统操作"
            }
        }
        
        -- 生成页脚信息（显示插件加载统计）
        local function get_footer()
            local stats = require("lazy").stats()
            local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
            return "⚡ Neovim loaded " .. stats.count .. " plugins in " .. ms .. "ms"
        end
        
        -- 设置 mini.starter
        starter.setup({
            -- 自动打开启动页面
            autoopen = true,
            -- 不自动执行单个活动项目
            evaluate_single = false,
            -- 启动项目配置
            items = items,
            -- 页眉（logo）
            header = logo,
            -- 页脚（插件统计信息）
            footer = get_footer,
            -- 查询更新字符（移除 't' 以避免与 neo-tree 快捷键冲突）
            query_updaters = 'abcdefghijklmnopqrsuvwxyz0123456789_-.',
            -- 内容钩子，用于自定义显示
            content_hooks = {
                -- 添加空行分隔
                starter.gen_hook.adding_bullet("│ ", false),
                -- 按部分对齐
                starter.gen_hook.aligning("center", "center")
            }
        })
        
        -- 处理 Lazy 插件管理器的显示逻辑
        if vim.o.filetype == "lazy" then
            vim.cmd.close()
            vim.api.nvim_create_autocmd("User", {
                pattern = "MiniStarterOpened",
                callback = function()
                    require("lazy").show()
                end,
            })
        end
        
        -- 在 Lazy 启动完成后更新页脚信息
        vim.api.nvim_create_autocmd("User", {
            pattern = "LazyVimStarted",
            callback = function()
                -- 刷新 starter 页面以显示更新的统计信息
                if vim.bo.filetype == "starter" then
                    require("mini.starter").refresh()
                end
            end,
        })
    end,
}