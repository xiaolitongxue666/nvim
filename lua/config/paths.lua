-- 配置目录路径辅助模块
-- init.lua 在 require 任何 config 模块前写入 vim.g.nvim_config_dir

local M = {}

--- 返回 Neovim 配置根目录（优先自愈后的全局值）
function M.config_dir()
  return vim.g.nvim_config_dir or vim.fn.stdpath("config")
end

--- lazy-lock.json 完整路径
function M.lockfile_path()
  return M.config_dir() .. "/lazy-lock.json"
end

--- 插件规格 glob 模式
function M.plugins_glob()
  return M.config_dir() .. "/lua/plugins/*.lua"
end

return M
