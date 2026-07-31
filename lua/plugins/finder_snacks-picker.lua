-- folke/snacks.nvim picker（替代 nvim-telescope/telescope.nvim）
-- 统一用已启用的 snacks.picker（opencode 亦依赖），消除双 picker 冗余。
-- 键位与原 telescope 一致（<leader>f* / <leader>g* / <leader>l* / <leader>rs）。
-- API 说明：顶层源直接调用（files/grep/...）；聚合源经 pick("源名")（commands/git_*/lsp_*/qflist 等）。
-- 移除项：<leader>fv vim_options、<leader>fp planets（snacks 无对应，低频）。
-- https://github.com/folke/snacks.nvim

return {
    {
        "folke/snacks.nvim",
        -- 核心 opts 在 ui_snacks.lua（input/picker/terminal 启用）；这里只挂 picker 键位
        event = "VeryLazy",
        keys = {
            -- 文件 / 搜索
            { "<leader>ff", function() require("snacks").picker.files() end, desc = "查找文件" },
            { "<leader>fg", function() require("snacks").picker.grep() end, desc = "实时搜索" },
            { "<leader>fb", function() require("snacks").picker.buffers() end, desc = "缓冲区列表" },
            { "<leader>fh", function() require("snacks").picker.help() end, desc = "帮助标签" },
            { "<leader>fr", function() require("snacks").picker.recent() end, desc = "最近文件" },
            { "<leader>fc", function() require("snacks").picker.pick("commands") end, desc = "命令列表" },
            { "<leader>fk", function() require("snacks").picker.pick("keymaps") end, desc = "键位映射" },
            { "<leader>fs", function() require("snacks").picker.grep_word() end, desc = "搜索当前单词" },
            { "<leader>fd", function() require("snacks").picker.diagnostics() end, desc = "诊断信息" },
            { "<leader>ft", function() require("snacks").picker.treesitter() end, desc = "Treesitter 符号" },
            { "<leader>fm", function() require("snacks").picker.pick("marks") end, desc = "标记列表" },
            { "<leader>fj", function() require("snacks").picker.pick("jumps") end, desc = "跳转列表" },
            { "<leader>fq", function() require("snacks").picker.pick("qflist") end, desc = "快速修复列表" },
            { "<leader>fl", function() require("snacks").picker.pick("loclist") end, desc = "位置列表" },
            { "<leader>fz", function() require("snacks").picker.lines() end, desc = "当前缓冲区模糊搜索" },
            { "<leader>rs", function() require("snacks").picker.resume() end, desc = "恢复上次搜索" },
            -- Git 相关
            { "<leader>gf", function() require("snacks").picker.pick("git_files") end, desc = "Git 文件" },
            { "<leader>gc", function() require("snacks").picker.pick("git_log") end, desc = "Git 提交" },
            { "<leader>gb", function() require("snacks").picker.pick("git_branches") end, desc = "Git 分支" },
            { "<leader>gs", function() require("snacks").picker.pick("git_status") end, desc = "Git 状态" },
            { "<leader>gt", function() require("snacks").picker.pick("git_stash") end, desc = "Git 暂存" },
            -- LSP 相关
            { "<leader>lr", function() require("snacks").picker.pick("lsp_references") end, desc = "LSP 引用" },
            { "<leader>ld", function() require("snacks").picker.pick("lsp_definitions") end, desc = "LSP 定义" },
            { "<leader>li", function() require("snacks").picker.pick("lsp_implementations") end, desc = "LSP 实现" },
            { "<leader>lt", function() require("snacks").picker.pick("lsp_type_definitions") end, desc = "LSP 类型定义" },
            { "<leader>ls", function() require("snacks").picker.pick("lsp_symbols") end, desc = "文档符号" },
            { "<leader>lw", function() require("snacks").picker.pick("lsp_symbols", { workspace = true }) end, desc = "工作区符号" },
        },
    },
}
