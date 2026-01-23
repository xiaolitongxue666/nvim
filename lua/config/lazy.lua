-- lazy.nvim

-- Neovim 的现代插件管理器

-- https://github.com/folke/lazy.nvim

-- 引导 lazy.nvim
-- 获取数据目录路径，并确保路径格式正确（去除可能的引号）
local datapath = vim.fn.stdpath("data")
-- 去除路径两端的引号（如果环境变量值包含引号）
datapath = string.gsub(datapath, "^[\"']+", "")
datapath = string.gsub(datapath, "[\"']+$", "")
-- 规范化路径，确保使用正斜杠（Neovim 内部使用正斜杠）
datapath = vim.fn.fnamemodify(datapath, ":p")
datapath = string.gsub(datapath, "\\", "/")
-- 移除末尾的斜杠（如果有）
datapath = string.gsub(datapath, "/+$", "")
local lazypath = datapath .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- 注意：mapleader 和 maplocalleader 已在 keybindings.lua 中设置
-- keybindings.lua 在 lazy.lua 之前加载（见 init.lua），因此这里不需要重复设置
-- 这也是设置其他配置 (vim.opt) 的好地方

-- 禁用 LazyVim 导入顺序检查（不使用 LazyVim）
vim.g.lazyvim_check_order = false

-- 设置 lazy.nvim
require("lazy").setup({
    spec = {
        -- 导入你的插件
        { import = "plugins" },
    },
    -- 在这里配置任何其他设置。查看文档了解更多详情。
    -- 安装插件时使用的配色方案。
    install = { colorscheme = { "habamax" } },
    -- 自动检查插件更新
    checker = { enabled = true },
})
