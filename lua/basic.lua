-- 文件以utf8格式加载
vim.g.encoding = "UTF-8"
vim.o.fileencoding = "utf-8"
-- jk移动时光标下上方保留8行
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8
-- 是否使用相对行号
vim.wo.number = true
vim.wo.relativenumber = true
-- 同时显示行号和相对行号
vim.o.statuscolumn = "%s %l %r"
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
-- 鼠标支持
vim.o.mouse = "a"
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

-- 根据操作系统设置shell
if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
	-- Windows 系统使用 Git Bash
	-- 设置正确的 Git Bash 路径
	vim.opt.shell = "\"D:\\Program Files\\Git\\bin\\bash.exe\""
	vim.opt.shellcmdflag = "-c"
	vim.opt.shellquote = ""
	vim.opt.shellxquote = ""
	vim.opt.shellpipe = "|"
	vim.opt.shellredir = ">"
	-- 使用正斜杠路径，避免插件在解析 runtimepath 时出错
	vim.opt.shellslash = true
else
	-- macOS 和 Linux 使用默认 shell
	-- 不需要特殊设置，使用系统默认
end

