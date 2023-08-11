-- https://patorjk.com/software/taag/#p=display&f=Larry%203D&t=Leon
-- __
--/\ \
--\ \ \         __    ___     ___
-- \ \ \  __  /'__`\ / __`\ /' _ `\
--  \ \ \L\ \/\  __//\ \L\ \/\ \/\ \
--   \ \____/\ \____\ \____/\ \_\ \_\
--    \/___/  \/____/\/___/  \/_/\/_/

-- Lua 版本
--   https://neovim.io/doc/user/index.html
--   https://github.com/nshen/learn-neovim-lua
--   https://github.com/nanotee/nvim-lua-guide#defining-mappings

-- 整体基础设置
require("basic")
-- 整体快捷键映射 & 插件快捷键配置
require("keybindings")
-- lazy.nvim插件管理
require("lazynvim")
