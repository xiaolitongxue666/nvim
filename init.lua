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

-- ==========================================
-- 自愈：检测并修复配置文件路径不匹配
--
-- 解决 Windows 下 Neovim 期望 %LOCALAPPDATA%/nvim
-- 但配置实际在 ~/.config/nvim 的问题，以及任何
-- stdpath('config') ≠ init.lua 实际位置的场景。
--
-- 修复两个独立的寻址机制：
--   1. package.path — Lua 模块搜索路径（require() 依赖此）
--   2. runtimepath — Vim 搜索路径（lazy.nvim 加载插件依赖此）
--
-- 两者都在使用前立即修复：
--   - package.path 在 require("basic") 之前修
--   - runtimepath 在 require("config.lazy") 之前修
-- 同时通过 VimEnter 自动命令防止启动后 rtp 被重置。
--   因为某些平台通过 -u init.lua 加载后 Neovim 会重算 rtp。
-- ==========================================

-- Windows：在 stdpath/health 计算前展开 USERPROFILE 等（避免 %USERPROFILE% 字面量）
if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
  local function expand_win_env(name)
    local value = vim.env[name] or ""
    if value == "" or value:find("%%") then
      local ok, result = pcall(function()
        return vim.fn.system('cmd /c "echo %' .. name .. '%"'):gsub("^%s+", ""):gsub("%s+$", ""):gsub("[\r\n]", "")
      end)
      if ok and result and result ~= "" and not result:find("%%") then
        vim.env[name] = result
      end
    end
  end
  expand_win_env("USERPROFILE")
  expand_win_env("APPDATA")
  expand_win_env("LOCALAPPDATA")
  if not vim.env.XDG_CONFIG_HOME or vim.env.XDG_CONFIG_HOME == "" then
    vim.env.XDG_CONFIG_HOME = vim.fn.expand("~/.config")
  end
end

local function find_our_config_dir()
  -- 优先 init.lua 实际路径（-u init.lua / 仓库即 ~/.config/nvim 时，避免 stdpath 指向 msys 旧副本）
  local src = (debug.getinfo(1, "S") or {}).source or ""
  src = src:gsub("^@", "")
  if src ~= "" then
    local script_dir = vim.fn.fnamemodify(src, ":p:h")
    if vim.fn.filereadable(script_dir .. "/lua/basic.lua") == 1 then
      return script_dir
    end
  end

  -- 检查 stdpath('config') 是否已有我们的文件
  local expected = vim.fn.stdpath("config")
  if vim.fn.filereadable(expected .. "/lua/basic.lua") == 1 then
    return expected
  end

  -- 检查 XDG 配置路径（兼容自定义 XDG_CONFIG_HOME）
  local xdg_base = vim.env.XDG_CONFIG_HOME
  if not xdg_base or xdg_base == "" then
    xdg_base = vim.fn.expand("~/.config")
  end
  local fs_join = vim.fs.joinpath or vim.fs.join
  local candidate = fs_join(xdg_base, "nvim")
  if vim.fn.filereadable(candidate .. "/lua/basic.lua") == 1 then
    return candidate
  end

  return nil
end

local function fix_runtimepath(dir)
  if not dir then
    return
  end
  -- 重构 rtp，把我们的目录放在最前面。
  -- 直接用 vim.o.rtp 赋值比 :prepend/:set^= 更可靠，
  -- 因为某些平台通过 -u init.lua 加载后 Neovim 会重算 rtp。
  local rtp_list = vim.split(vim.o.rtp, ",")
  local norm = dir:gsub("\\", "/")
  local found = false
  for _, p in ipairs(rtp_list) do
    if p:gsub("\\", "/") == norm then
      found = true
      break
    end
  end
  if not found then
    vim.o.rtp = dir .. "," .. vim.o.rtp
  end
end

local function fix_package_path(dir)
  local lua_dir = dir .. "/lua"
  if vim.fn.isdirectory(lua_dir) ~= 1 then
    return
  end
  local prefix = lua_dir .. "/?.lua;" .. lua_dir .. "/?/init.lua;"
  if not package.path:find(prefix, 1, true) then
    package.path = prefix .. package.path
  end
end

-- 一次性找到配置目录，全局复用
local our_config = find_our_config_dir()
if our_config then
  vim.g.nvim_config_dir = our_config
end

-- 第一阶段：立即修复 package.path（在 require("basic") 之前）
fix_package_path(our_config)

-- 第二阶段：通过 VimEnter 自动命令修复 runtimepath
-- 某些平台通过 -u init.lua 加载后 Neovim 会重算 rtp，
-- 覆盖初始化期间对 rtp 的改动，因此需要延迟到启动完成后修正。
if our_config then
  -- VimEnter 在所有初始化完成后触发
  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("ConfigPathFix", { clear = true }),
    once = true,
    callback = function()
      fix_runtimepath(our_config)
    end,
  })
end

-- ==========================================

-- 整体基础设置
require("basic")
-- 整体快捷键映射 & 插件快捷键配置
require("keybindings")
-- 智能窗口控制
require("window_control").setup_keymaps()

-- 第三阶段：在 lazy.nvim 加载插件前立即修复 runtimepath
-- VimEnter 自动命令的触发时机可能晚于 lazy.nvim 的插件扫描
fix_runtimepath(our_config)

-- lazy.nvim 插件管理
require("config.lazy")

-- ==========================================
-- 自动配置路径（请勿手动编辑）
-- ==========================================

local function file_exists(path)
    return path ~= nil and path ~= "" and vim.fn.filereadable(path) == 1
end

local function detect_python_host_from_uv()
    -- 优先使用自愈后的路径，其次回退到 stdpath('config')
    local config_dir = our_config or vim.fn.stdpath("config")
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
        return
    end
    -- 全局 npm 包不在 node 默认可解析路径；用 npm root -g 定位 cli.js
    if vim.fn.executable("npm") == 1 then
        local npm_root = vim.fn.systemlist("npm root -g")
        if vim.v.shell_error == 0 and npm_root and npm_root[1] then
            local cli = vim.trim(npm_root[1]:gsub("\r", ""):gsub("\\", "/")) .. "/neovim/bin/cli.js"
            if file_exists(cli) then
                vim.g.node_host_prog = cli
            end
        end
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
