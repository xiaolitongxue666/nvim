-- 文件以utf8格式加载
vim.g.encoding = "UTF-8"
-- 与 Neovim 0.11 默认一致，注释保留
-- vim.o.fileencoding = "utf-8"

-- Windows 环境变量路径修复（处理 Git Bash 环境下的引号问题）
if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    -- 清理环境变量中的引号
    local function clean_env_path(env_name)
        local value = vim.env[env_name]
        if value and value:match('["\']') then
            vim.env[env_name] = value:gsub('["\']', "")
        end
    end
    
    -- 修复可能包含引号的 XDG 环境变量
    clean_env_path("XDG_DATA_HOME")
    clean_env_path("XDG_CONFIG_HOME")
    clean_env_path("XDG_STATE_HOME")
    clean_env_path("XDG_CACHE_HOME")
end

-- 代理环境变量设置（跨平台兼容）
-- 优先级：系统环境变量 > NVIM_PROXY_URL 环境变量 > 不设置（保持兼容性）
-- 推荐：在终端中先 export http_proxy=... https_proxy=... 再启动 nvim，这样 lazy/mason/treesitter 等所有子进程都会走代理。
-- 注意：nvim-treesitter 使用 Git 下载，需要确保 Git 和 Neovim 都能使用代理
local function setup_proxy()
    -- 如果系统环境变量已设置，直接使用（会自动继承）
    if vim.env.http_proxy or vim.env.HTTP_PROXY then
        -- 统一设置 all_proxy 与 no_proxy，部分工具只认 all_proxy
        local proxy = vim.env.https_proxy or vim.env.HTTP_PROXY or vim.env.http_proxy
        if proxy and (not vim.env.all_proxy or vim.env.all_proxy == "") then
            vim.env.all_proxy = proxy
        end
        if not vim.env.no_proxy or vim.env.no_proxy == "" then
            vim.env.no_proxy = "127.0.0.1,localhost"
        end
        return
    end

    -- 尝试从 NVIM_PROXY_URL 环境变量获取（如果用户设置了）
    -- 使用方法：在启动 Neovim 前设置 export NVIM_PROXY_URL=http://127.0.0.1:7890
    local proxy_url = os.getenv("NVIM_PROXY_URL")
    if proxy_url and proxy_url ~= "" then
        vim.env.http_proxy = proxy_url
        vim.env.https_proxy = proxy_url
        vim.env.HTTP_PROXY = proxy_url
        vim.env.HTTPS_PROXY = proxy_url
        vim.env.all_proxy = proxy_url
        vim.env.no_proxy = "127.0.0.1,localhost"
    end
end

setup_proxy()

-- 确保编译工具在 PATH 中（仅 Windows）
-- macOS 和 Linux 通常通过包管理器安装，gcc 已在系统 PATH 中
if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    -- 添加 MinGW 到 PATH（如果 gcc 不可用）
    if vim.fn.executable("gcc") == 0 then
        local mingw_paths = {
            "C:\\msys64\\mingw64\\bin",
            "C:\\ProgramData\\mingw64\\mingw64\\bin",
        }
        local current_path = vim.env.PATH or ""
        local path_separator = ";"  -- Windows 使用分号
        for _, path in ipairs(mingw_paths) do
            if vim.fn.isdirectory(path) == 1 and not string.find(current_path, path, 1, true) then
                vim.env.PATH = path .. path_separator .. current_path
                break
            end
        end
    end
end
-- jk移动时光标下上方保留8行
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8
-- 是否使用相对行号
vim.wo.number = true
vim.wo.relativenumber = true
-- 同时显示行号和相对行号（与 Neovim 0.11 默认一致时注释保留）
-- vim.o.statuscolumn = "%s %l %r"
-- 高亮所在行
vim.wo.cursorline = true
-- 显示左侧图标指示列
vim.wo.signcolumn = "yes"
-- 右侧参考线，超过表示代码太长了，考虑换行
vim.wo.colorcolumn = "80"
-- 缩进4个空格等于一个Tab
vim.o.tabstop = 4
vim.bo.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftround = true
-- 键入'>>'和'<<' 时移动长度,类似Tab和逆向Tab
vim.o.shiftwidth = 4
vim.bo.shiftwidth = 4
-- 新行对齐当前行，空格替代tab
vim.o.expandtab = true
vim.bo.expandtab = true
vim.o.autoindent = true
vim.bo.autoindent = true
vim.o.smartindent = true
-- 搜索大小写不敏感，除非包含大写
vim.o.ignorecase = true
vim.o.smartcase = true
-- 搜索高亮
vim.o.hlsearch = true
-- 边输入边搜索
vim.o.incsearch = true
-- 使用增强状态栏后不再需要 vim 的模式提示
vim.o.showmode = false
-- 命令行高为2，提供足够的显示空间
vim.o.cmdheight = 2
-- 当文件被外部程序修改时，自动加载
vim.o.autoread = true
vim.bo.autoread = true
-- 自动换行
vim.o.wrap = true
vim.wo.wrap = false
-- 行结尾可以跳到下一行
vim.o.whichwrap = "b,s,<,>,[,],h,l"
-- 允许隐藏被修改过的buffer
vim.o.hidden = true
-- 与 Neovim 0.11 默认一致，注释保留
-- vim.o.mouse = "a"
-- 禁止创建备份文件
vim.o.backup = false
vim.o.writebackup = false
vim.o.swapfile = false
-- 更小的更新时间
vim.o.updatetime = 300
-- 设置 timeoutlen 为等待键盘快捷键连击时间200毫秒，可根据需要设置
-- 遇到问题详见：https://github.com/nshen/learn-neovim-lua/issues/1
-- vim.o.timeoutlen = 200
-- 分屏窗口从下边和右边出现
vim.o.splitbelow = true
vim.o.splitright = true
-- 自动补全不自动选中
vim.g.completeopt = "menu,menuone,noselect,noinsert"
-- 样式
vim.o.background = "dark"
vim.o.termguicolors = true
vim.opt.termguicolors = true
-- 不可见字符的显示，这里只把空格显示为一个点
vim.o.list = true
-- vim.o.listchars = "space:-,tab:>~,eol:↵"
vim.opt.listchars = {
	eol = "↵",
	-- space = "●",
	-- tab = "|",
	tab = ">~",
}
-- 补全增强
vim.o.wildmenu = true
-- 不向插入补全菜单传递消息
vim.o.shortmess = vim.o.shortmess .. "c"
vim.o.pumheight = 10
-- 始终显示标签栏
vim.o.showtabline = 2
-- 在下次打开文件的时候光标位置
vim.cmd([[autocmd BufReadPost * if line("'\"") >= 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif ]])
-- 拷贝到剪切板
vim.o.clipboard = "unnamed"

-- 检查 clipboard provider 是否可用（延迟检查，因为 provider 可能在启动后才可用）
vim.schedule(function()
    -- 检查是否在 SSH 环境中（DISPLAY 为空通常表示无 X11 转发）
    local is_ssh_env = (vim.env.SSH_CLIENT ~= nil or vim.env.SSH_CONNECTION ~= nil) and (vim.env.DISPLAY == nil or vim.env.DISPLAY == "")

    -- 检查是否有可用的 clipboard 工具
    local clipboard_tool = nil
    if vim.fn.executable("xclip") == 1 then
        clipboard_tool = "xclip"
    elseif vim.fn.executable("xsel") == 1 then
        clipboard_tool = "xsel"
    elseif vim.fn.executable("pbcopy") == 1 and vim.fn.executable("pbpaste") == 1 then
        clipboard_tool = "pbcopy/pbpaste"
    end

    -- 检查 Neovim 是否检测到 clipboard provider
    if vim.fn.has("clipboard") == 0 then
        -- Neovim 编译时没有 clipboard 支持
        if clipboard_tool and not is_ssh_env then
            -- 只在非 SSH 环境中显示警告
            vim.notify("Clipboard tool found: " .. clipboard_tool .. ", but Neovim was not compiled with clipboard support. Reinstall Neovim with clipboard support.", vim.log.levels.WARN)
        end
    elseif is_ssh_env and clipboard_tool then
        -- SSH 环境且无 X11 转发：这是正常情况，不显示警告
        -- 用户可以通过安装 X 服务器（如 VcXsrv）并启用 X11 转发来使用 clipboard
    end
end)
-- 在 copy 后高亮
vim.api.nvim_create_autocmd({ "TextYankPost" }, {
	pattern = { "*" },
	callback = function()
		vim.hl.on_yank({
			timeout = 300,
		})
	end,
})

-- 禁用不需要的 provider（消除健康检查警告）
-- Perl provider: 版本太旧，不需要
vim.g.loaded_perl_provider = 0
-- Ruby provider: 本配置未使用 Ruby 插件，可不安装 Ruby
vim.g.loaded_ruby_provider = 0

-- 根据操作系统设置shell
if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
	-- Windows 系统：使用 PowerShell 或 CMD（更好的路径兼容性）
	-- 注意：Git Bash + shellslash 会导致 nvim-treesitter 等插件的路径解析问题
	-- 如果需要使用 Git Bash，请在外部终端中运行，而不是作为 Neovim 的内置 shell
	vim.opt.shell = "pwsh.exe"
	vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
	vim.opt.shellquote = ""
	vim.opt.shellxquote = ""
	vim.opt.shellpipe = "| Out-File -Encoding UTF8 %s"
	vim.opt.shellredir = "| Out-File -Encoding UTF8 %s"
	-- 注意：不要设置 shellslash = true，这会导致路径解析问题
else
	-- macOS 和 Linux 使用默认 shell
	-- 不需要特殊设置，使用系统默认
end

