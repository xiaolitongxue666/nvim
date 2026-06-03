-- lazy.nvim
-- vim: noet ts=2 sts=2 sw=2

-- Neovim 的现代插件管理器

-- https://github.com/folke/lazy.nvim

-- 引导 lazy.nvim
-- 获取数据目录路径
local datapath = vim.fn.stdpath("data")
-- 清理路径中可能存在的引号（Windows 环境变量问题）
datapath = string.gsub(tostring(datapath), '["\']', "")
local lazypath = datapath .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
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

-- 清理路径函数（处理 Windows + Git Bash 环境变量问题）
local function clean_path(path)
    if type(path) == "table" then
        path = path[1]
    end
    return string.gsub(tostring(path), '["\']', "")
end

-- 手动收集所有插件规格（不依赖 runtimepath，解决路径不匹配时找不到插件的问题）
local function collect_plugin_specs()
    local our_config = vim.fn.expand("~/.config/nvim")
    local plugin_files = vim.fn.glob(our_config .. "/lua/plugins/*.lua", false, true)
    local specs = {}
    for _, file in ipairs(plugin_files) do
        -- Windows glob 返回 C:\...\lua\plugins\foo.lua，需兼容正反斜杠
        local modname = file:gsub("^.+[\\/]lua[\\/]", ""):gsub("%.lua$", ""):gsub("[/\\]", ".")
        local ok, result = pcall(require, modname)
        if ok and type(result) == "table" then
            -- 多 spec 文件：return { { spec1 }, { spec2 } }（首元素为 table）
            -- 单 spec 简写：return { "plugin/name", lazy = false, config = ... }（首元素为 string）
            if type(result[1]) == "table" then
                for _, spec in ipairs(result) do
                    table.insert(specs, spec)
                end
            else
                table.insert(specs, result)
            end
        end
    end
    return specs
end

-- 设置 lazy.nvim
require("lazy").setup({
    spec = collect_plugin_specs(),
    -- 在这里配置任何其他设置。查看文档了解更多详情。
    -- 安装插件时使用的配色方案。
    install = { colorscheme = { "habamax" } },
    -- 自动检查插件更新
    checker = { enabled = true },
    -- 显式设置路径（修复 Windows + Git Bash 路径问题）
    root = clean_path(vim.fn.stdpath("data")) .. "/lazy",
    state = clean_path(vim.fn.stdpath("state")) .. "/lazy/state.json",
    -- 锁文件路径：使用实际配置目录而非 stdpath('config')（Windows 路径不匹配时修正）
    lockfile = vim.fn.expand("~/.config/nvim") .. "/lazy-lock.json",
    performance = {
        cache = {
            enabled = false, -- 禁用 vim.loader 缓存（修复 Windows + Git Bash 路径问题）
        },
    },
    -- 显式设置 pkg.cache 路径（修复 Windows 路径解析问题）
    pkg = {
        cache = clean_path(vim.fn.stdpath("state")) .. "/lazy/pkg-cache.lua",
    },
    -- 禁用 luarocks/hererocks，消除 checkhealth 中 lazy 的 ERROR（无插件依赖 luarocks）
    rocks = { enabled = false },
})