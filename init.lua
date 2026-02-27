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

-- Python interpreter path (auto-configured by install.sh)
vim.g.python3_host_prog = "/root/.config/nvim/venv/nvim-python/bin/python"
-- Add virtual environment site-packages to pythonpath
local venv_path = "/root/.config/nvim/venv/nvim-python"
vim.opt.pp:prepend(venv_path .. "/lib/python*/site-packages")

-- Node.js host script path (auto-configured by install.sh; must be path to neovim/bin/cli.js)
vim.g.node_host_prog = "/root/.local/share/fnm/node-versions/v24.14.0/installation/lib/node_modules/neovim/bin/cli.js"

-- ==========================================
-- Auto-configured paths (do not edit manually)
-- ==========================================

-- opencode CLI path (auto-configured by install.sh when found in PATH)
vim.g.opencode_cmd = "/c/opencode/opencode"
