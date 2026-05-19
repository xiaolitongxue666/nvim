-- https://patorjk.com/software/taag/#p=display&f=Larry%203D&t=Leon
-- __
--/\ \
--\ \ \         __    ___     ___
-- \ \ \  __  /'__`\ / __`\ /' _ `\
--  \ \ \L\ \/\  __//\ \L\ \/\ \/\ \
--   \ \____/\ \____\ \____/\ \_\ \_\
--    \/___/  \/____/\/___/  \/_/\/_/

-- Lua 版本配置
--   Neovim 官方文档: https://neovim.io/doc/user/index.html
--   Neovim Lua 学习指南: https://github.com/nshen/learn-neovim-lua
--   Neovim Lua 映射定义指南: https://github.com/nanotee/nvim-lua-guide#defining-mappings

-- 整体基础设置
require("basic")
-- 整体快捷键映射 & 插件快捷键配置
require("keybindings")
-- 智能窗口控制
require("window_control").setup_keymaps()
-- lazy.nvim插件管理
require("config.lazy")

-- ==========================================
-- Auto-configured paths (do not edit manually)
-- ==========================================

local function file_exists(path)
    return path ~= nil and path ~= "" and vim.fn.filereadable(path) == 1
end

local function detect_python_host_from_uv()
    local config_dir = vim.fn.stdpath("config")
    local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
    local python_in_venv = is_windows
        and (config_dir .. "/venv/nvim-python/Scripts/python.exe")
        or (config_dir .. "/venv/nvim-python/bin/python")
    if file_exists(python_in_venv) then
        vim.g.python3_host_prog = python_in_venv
    end
end

local function detect_node_host_from_fnm()
    if vim.fn.executable("node") ~= 1 then
        return
    end
    local resolved = vim.fn.systemlist([[node -p "require.resolve('neovim/bin/cli.js')"]])
    if vim.v.shell_error == 0 and resolved and resolved[1] and file_exists(resolved[1]) then
        vim.g.node_host_prog = resolved[1]
    end
end

local function detect_opencode()
    if vim.fn.executable("opencode") == 1 then
        vim.g.opencode_cmd = vim.fn.exepath("opencode")
    end
end

detect_python_host_from_uv()
detect_node_host_from_fnm()
detect_opencode()
