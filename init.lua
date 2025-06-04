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
-- lazy.nvim插件管理
require("config.lazy")