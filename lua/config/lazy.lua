-- lazy.nvim

-- Neovim 的现代插件管理器

-- https://github.com/folke/lazy.nvim

-- 引导 lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
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

-- 确保在加载 lazy.nvim 之前设置 `mapleader` 和 `maplocalleader`
-- 以便映射正确。
-- 这也是设置其他配置 (vim.opt) 的好地方
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

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