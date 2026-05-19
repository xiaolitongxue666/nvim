-- VSCode Neovim 配置文件
-- 基于原始 basic.lua 和 keybindings.lua，但移除了插件依赖的功能

-- ============================================================================
-- 基础设置 (来自 basic.lua)
-- ============================================================================

-- 文件编码设置
vim.g.encoding = "UTF-8"
vim.o.fileencoding = "utf-8"

-- Windows 环境变量路径修复（处理 Git Bash 环境下的引号问题）
if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    local function clean_env_path(environment_variable_name)
        local environment_variable_value = vim.env[environment_variable_name]
        if environment_variable_value and environment_variable_value:match('["\']') then
            vim.env[environment_variable_name] = environment_variable_value:gsub('["\']', "")
        end
    end

    clean_env_path("XDG_DATA_HOME")
    clean_env_path("XDG_CONFIG_HOME")
    clean_env_path("XDG_STATE_HOME")
    clean_env_path("XDG_CACHE_HOME")

    local appdata = vim.env.APPDATA or ""
    if appdata == "" or appdata:find("%%") then
        local ok, result = pcall(function()
            return vim.fn.system('cmd /c "echo %APPDATA%"'):gsub("^%s+", ""):gsub("%s+$", ""):gsub("[\r\n]", "")
        end)
        if ok and result and result ~= "" then
            vim.env.APPDATA = result
        end
    end
end

-- 代理环境变量设置（跨平台兼容）
local function setup_proxy()
    if vim.env.http_proxy or vim.env.HTTP_PROXY then
        local active_proxy = vim.env.https_proxy or vim.env.HTTP_PROXY or vim.env.http_proxy
        if active_proxy and (not vim.env.all_proxy or vim.env.all_proxy == "") then
            vim.env.all_proxy = active_proxy
        end
        if not vim.env.no_proxy or vim.env.no_proxy == "" then
            vim.env.no_proxy = "127.0.0.1,localhost"
        end
        return
    end

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

-- Windows 下确保 gcc 在 PATH 中（供 Treesitter / 构建工具使用）
if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    if vim.fn.executable("gcc") == 0 then
        local mingw_candidate_paths = {
            "C:\\msys64\\mingw64\\bin",
            "C:\\ProgramData\\mingw64\\mingw64\\bin",
        }
        local current_environment_path = vim.env.PATH or ""
        local windows_path_separator = ";"
        for _, candidate_path in ipairs(mingw_candidate_paths) do
            if vim.fn.isdirectory(candidate_path) == 1 and not string.find(current_environment_path, candidate_path, 1, true) then
                vim.env.PATH = candidate_path .. windows_path_separator .. current_environment_path
                break
            end
        end
    end
end

-- 光标移动时保留行数
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8

-- 行号设置
vim.wo.number = true
vim.wo.relativenumber = true

-- 高亮当前行
vim.wo.cursorline = true
vim.wo.signcolumn = "yes"
vim.wo.colorcolumn = "80"

-- 缩进设置
vim.o.tabstop = 4
vim.bo.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftround = true
vim.o.shiftwidth = 4
vim.bo.shiftwidth = 4
vim.o.expandtab = true
vim.bo.expandtab = true
vim.o.autoindent = true
vim.bo.autoindent = true
vim.o.smartindent = true

-- 搜索设置
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hlsearch = true
vim.o.incsearch = true

-- 界面设置
vim.o.showmode = false
vim.o.cmdheight = 2

-- 文件处理
vim.o.autoread = true
vim.bo.autoread = true
vim.o.wrap = true
vim.wo.wrap = false
vim.o.whichwrap = "b,s,<,>,[,],h,l"
vim.o.hidden = true

-- 鼠标支持
vim.o.mouse = "a"

-- 备份文件设置
vim.o.backup = false
vim.o.writebackup = false
vim.o.swapfile = false

-- 更新时间
vim.o.updatetime = 300

-- 分屏设置
vim.o.splitbelow = true
vim.o.splitright = true

-- 补全设置
vim.g.completeopt = "menu,menuone,noselect,noinsert"
vim.o.wildmenu = true
vim.o.shortmess = vim.o.shortmess .. "c"
vim.o.pumheight = 10

-- 样式设置 (VSCode 会处理大部分主题，但保留基础设置)
vim.o.background = "dark"
vim.o.termguicolors = true
vim.opt.termguicolors = true

-- 不可见字符显示
vim.o.list = true
vim.opt.listchars = {
    eol = "↵",
    tab = ">~",
}

-- 恢复光标位置
vim.cmd([[autocmd BufReadPost * if line("'\"") >= 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif ]])

-- 剪贴板设置
vim.o.clipboard = "unnamed"

-- Clipboard provider 检查（与主配置保持一致）
vim.schedule(function()
    local is_ssh_environment = (vim.env.SSH_CLIENT ~= nil or vim.env.SSH_CONNECTION ~= nil) and
        (vim.env.DISPLAY == nil or vim.env.DISPLAY == "")

    local clipboard_tool_name = nil
    if vim.fn.executable("xclip") == 1 then
        clipboard_tool_name = "xclip"
    elseif vim.fn.executable("xsel") == 1 then
        clipboard_tool_name = "xsel"
    elseif vim.fn.executable("pbcopy") == 1 and vim.fn.executable("pbpaste") == 1 then
        clipboard_tool_name = "pbcopy/pbpaste"
    end

    if vim.fn.has("clipboard") == 0 then
        if clipboard_tool_name and not is_ssh_environment then
            vim.notify(
                "Clipboard tool found: " .. clipboard_tool_name ..
                ", but Neovim was not compiled with clipboard support. Reinstall Neovim with clipboard support.",
                vim.log.levels.WARN
            )
        end
    end
end)

-- 复制后高亮
vim.api.nvim_create_autocmd({ "TextYankPost" }, {
    pattern = { "*" },
    callback = function()
        vim.hl.on_yank({
            timeout = 300,
        })
    end,
})

-- 禁用不需要的 provider（与主配置一致）
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Windows shell 选项与主配置对齐
if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    vim.opt.shell = "pwsh.exe"
    vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
    vim.opt.shellquote = ""
    vim.opt.shellxquote = ""
    vim.opt.shellpipe = "| Out-File -Encoding UTF8 %s"
    vim.opt.shellredir = "| Out-File -Encoding UTF8 %s"
end

-- Windows：当 cwd 为配置目录时清理误建的 %APPDATA% 目录
local function normalize_path_for_compare(path_text)
    if not path_text or path_text == "" then
        return ""
    end
    path_text = path_text:gsub("\\", "/"):gsub("/+$", ""):lower()
    path_text = path_text:gsub("^/([a-z])/", "%1:/")
    return path_text
end

local function clean_appdata_in_config_dir()
    if vim.fn.has("win32") ~= 1 and vim.fn.has("win64") ~= 1 then
        return
    end
    local current_working_directory = normalize_path_for_compare(vim.fn.getcwd())
    local neovim_config_directory = normalize_path_for_compare(vim.fn.stdpath("config"))
    if current_working_directory == "" or neovim_config_directory == "" or current_working_directory ~= neovim_config_directory then
        return
    end
    local stray_appdata_directory = vim.fn.getcwd() .. "/%APPDATA%"
    if vim.fn.isdirectory(stray_appdata_directory) == 1 then
        vim.fn.delete(stray_appdata_directory, "rf")
        vim.notify("已清理配置目录下的 %APPDATA% 目录", vim.log.levels.INFO, { title = "NvimConfig" })
    end
end

vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        clean_appdata_in_config_dir()
    end,
    once = true,
})

vim.api.nvim_create_user_command(
    "NvimConfigCleanAppdata",
    clean_appdata_in_config_dir,
    { desc = "清理当前配置目录下的 %APPDATA% 目录（仅 Windows 且 cwd 为配置目录时有效）" }
)

-- ============================================================================
-- 按键绑定 (来自 keybindings.lua，移除了 VSCode 不适用的部分)
-- ============================================================================

-- 设置 Leader 键
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 按键映射选项
local map = vim.api.nvim_set_keymap
local opt = {
    noremap = true,
    silent = true
}

-- 基础文件操作 (在 VSCode 中这些可能由 VSCode 处理，但保留以防需要)
map("", "S", ":w<CR>", opt)
-- 注意：Q 退出在 VSCode 中可能不适用，注释掉
-- map("", "Q", ":q<CR>", opt)

-- 插入模式重映射
map("n", "h", "i", opt)
map("n", "H", "I", opt)
map("v", "h", "i", opt)
map("v", "H", ":I", opt)

-- 搜索导航
map("n", "n", "nzz", opt)
map("n", "N", "Nzz", opt)
map("n", "<LEADER><CR>", ":nohlsearch<CR>", opt)

-- 代码折叠
map("", "<LEADER>o", "za", opt)

-- 自定义光标移动 (ijkl 布局)
map("n", "i", "k", opt)
map("n", "k", "j", opt)
map("n", "j", "h", opt)
map("n", "l", "l", opt)

-- 可视模式下的光标移动
map("v", "i", "k", opt)
map("v", "k", "j", opt)
map("v", "j", "h", opt)
map("v", "l", "l", opt)

-- 快速光标移动
map("n", "I", "5k", opt)
map("n", "K", "5j", opt)
map("n", "J", "b", opt)   -- 按单词向左移动
map("n", "L", "w", opt)   -- 按单词向右移动

-- 跳转到行尾
map("n", "E", "$", opt)

-- 可视模式下的快速移动
map("v", "I", "5k", opt)
map("v", "K", "5j", opt)
map("v", "J", "b", opt)
map("v", "L", "w", opt)

-- 窗口管理 (在 VSCode 中可能部分功能由 VSCode 处理)
-- 分屏创建
map("", "si", ":set nosplitbelow<CR>:split<CR>:set splitbelow<CR>", opt)
map("", "sk", ":set splitbelow<CR>:split<CR>", opt)
map("", "sj", ":set nosplitright<CR>:vsplit<CR>:set splitright<CR>", opt)
map("", "sl", ":set splitright<CR>:vsplit<CR>", opt)

-- 窗口间移动
map("n", "<LEADER>i", "<C-w>k", opt)
map("n", "<LEADER>k", "<C-w>j", opt)
map("n", "<LEADER>j", "<C-w>h", opt)
map("n", "<LEADER>l", "<C-w>l", opt)

-- 窗口大小调整
map("", "<up>", ":res +5<CR>", opt)
map("", "<down>", ":res -5<CR>", opt)
map("", "<left>", ":vertical resize-5<CR>", opt)
map("", "<right>", ":vertical resize+5<CR>", opt)

-- 窗口布局调整
map("", "sh", "<C-w>t<C-w>K", opt)
map("", "sv", "<C-w>t<C-w>H", opt)
map("n", "srh", "<C-w>b<C-w>K", opt)
map("n", "srv", "<C-w>b<C-w>H", opt)

-- 窗口关闭 (在 VSCode 中可能不完全适用)
map("n", "<LEADER>q", "<C-w>j:q<CR>", opt)

-- Buffer 操作 (在 VSCode 中可能由 VSCode 的标签页处理)
map("n", "<LEADER>b", ":b #<CR>:bd #<CR>", opt)

-- 显示文件路径
map("n", "sp", "1<C-G>", opt)

-- 终端相关 (在 VSCode 中可能不适用，注释掉)
-- map("n", "<LEADER>/", ":set splitbelow<CR>:split<CR>:res +10<CR>:term<CR>", opt)
-- map("t", "<C-N>", "<C-\\><C-N>", opt)
-- map("t", "<C-O>", "<C-\\><C-N><C-O>", opt)

-- 字符大小写切换
map("n", "<LEADER>sc", "~", opt)

-- 撤销和重做操作
map("n", "u", "u", opt)  -- 撤销
map("n", "<C-r>", "<C-r>", opt)  -- 重做

-- 位置导航
map("n", "<A-[>", "<C-i>", opt)
map("n", "<A-]>", "<C-o>", opt)

-- ============================================================================
-- VSCode 特定设置
-- ============================================================================

-- 检测是否在 VSCode 环境中运行
if vim.g.vscode then
    -- VSCode 特定的设置可以在这里添加
    -- 例如：禁用某些在 VSCode 中不需要的功能
    vim.o.showtabline = 0  -- VSCode 有自己的标签页
    -- 定义键映射
    
    -- Comment.nvim 快捷键 - 代码注释功能
    vim.keymap.set('n', 'gcc', '<Cmd>call VSCodeNotify("editor.action.commentLine")<CR>', { silent = true })
    vim.keymap.set('n', 'gbc', '<Cmd>call VSCodeNotify("editor.action.blockComment")<CR>', { silent = true })
    vim.keymap.set('v', 'gc', '<Cmd>call VSCodeNotify("editor.action.commentLine")<CR>', { silent = true })
    vim.keymap.set('v', 'gb', '<Cmd>call VSCodeNotify("editor.action.blockComment")<CR>', { silent = true })
    vim.keymap.set('n', 'gcO', '<Cmd>call VSCodeNotify("editor.action.addCommentLine")<CR>', { silent = true })
    vim.keymap.set('n', 'gco', '<Cmd>call VSCodeNotify("editor.action.addCommentLine")<CR>', { silent = true })
    vim.keymap.set('n', 'gcA', '<Cmd>call VSCodeNotify("editor.action.addCommentLine")<CR>', { silent = true })
    
    -- Buffer 操作快捷键
    vim.keymap.set('n', '<leader>[', '<Cmd>call VSCodeNotify("workbench.action.previousEditor")<CR>', { silent = true })
    vim.keymap.set('n', '[b', '<Cmd>call VSCodeNotify("workbench.action.previousEditor")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>]', '<Cmd>call VSCodeNotify("workbench.action.nextEditor")<CR>', { silent = true })
    vim.keymap.set('n', ']b', '<Cmd>call VSCodeNotify("workbench.action.nextEditor")<CR>', { silent = true })
    
    -- 关闭当前缓冲区
    vim.keymap.set('n', '<leader>b', '<Cmd>call VSCodeNotify("workbench.action.closeActiveEditor")<CR>', { silent = true })
    
    -- ============================================================================
    -- 从 keybindings.lua 添加的快捷键 (使用 VSCode 命令实现)
    -- ============================================================================
    
    -- 文件保存 (S 键)
    vim.keymap.set('', 'S', '<Cmd>call VSCodeNotify("workbench.action.files.save")<CR>', { silent = true })
    
    -- 窗口管理 - 分屏创建
    vim.keymap.set('', 'si', '<Cmd>call VSCodeNotify("workbench.action.splitEditorUp")<CR>', { silent = true })  -- 上方分屏
    vim.keymap.set('', 'sk', '<Cmd>call VSCodeNotify("workbench.action.splitEditorDown")<CR>', { silent = true })  -- 下方分屏
    vim.keymap.set('', 'sj', '<Cmd>call VSCodeNotify("workbench.action.splitEditorLeft")<CR>', { silent = true })  -- 左侧分屏
    vim.keymap.set('', 'sl', '<Cmd>call VSCodeNotify("workbench.action.splitEditorRight")<CR>', { silent = true })  -- 右侧分屏
    
    -- 窗口间移动
    vim.keymap.set('n', '<leader>i', '<Cmd>call VSCodeNotify("workbench.action.focusAboveGroup")<CR>', { silent = true })  -- 移动到上方窗口
    vim.keymap.set('n', '<leader>k', '<Cmd>call VSCodeNotify("workbench.action.focusBelowGroup")<CR>', { silent = true })  -- 移动到下方窗口
    vim.keymap.set('n', '<leader>j', '<Cmd>call VSCodeNotify("workbench.action.focusLeftGroup")<CR>', { silent = true })  -- 移动到左侧窗口
    vim.keymap.set('n', '<leader>l', '<Cmd>call VSCodeNotify("workbench.action.focusRightGroup")<CR>', { silent = true })  -- 移动到右侧窗口
    
    -- 窗口关闭
    vim.keymap.set('n', '<leader>q', '<Cmd>call VSCodeNotify("workbench.action.closeActiveEditor")<CR>', { silent = true })  -- 关闭当前窗口
    
    -- Buffer 关闭 (切换到上一个 buffer 并关闭当前)
    vim.keymap.set('n', '<leader>bd', '<Cmd>call VSCodeNotify("workbench.action.closeActiveEditor")<CR>', { silent = true })  -- 关闭当前 buffer
    
    -- 打开终端窗口
    vim.keymap.set('n', '<leader>/', '<Cmd>call VSCodeNotify("workbench.action.terminal.toggleTerminal")<CR>', { silent = true })  -- 打开/关闭终端
    vim.keymap.set('n', '<leader>t', '<Cmd>call VSCodeNotify("workbench.action.terminal.new")<CR>', { silent = true })  -- 新建终端
    
    -- 终端模式下的快捷键
    vim.keymap.set('t', '<C-q>', '<Cmd>call VSCodeNotify("workbench.action.terminal.toggleTerminal")<CR>', { silent = true })  -- Ctrl+Q 关闭终端
    vim.keymap.set('t', '<C-[>', '<Cmd>call VSCodeNotify("workbench.action.focusActiveEditorGroup")<CR>', { silent = true })  -- Ctrl+[ 返回编辑器
    
    -- Neo-tree 文件浏览器及相关视图快捷

    -- <leader>fe: 打开文件资源管理器并聚焦
    -- 执行 `workbench.view.explorer` 打开或切换到文件资源管理器视图,
    -- 然后执行 `workbench.action.focusSideBar` 将焦点移到侧边栏, 方便立即操作文件树。
    vim.keymap.set('n', '<leader>fe', '<Cmd>call VSCodeNotify("workbench.view.explorer")<CR><Cmd>call VSCodeNotify("workbench.action.focusSideBar")<CR>', { silent = true, desc = "打开并聚焦文件浏览器" })

    -- <leader>e: 切换侧边栏的显示/隐藏状态
    -- 执行 `workbench.action.toggleSidebarVisibility`，这是一个纯粹的切换操作。
    -- 如果侧边栏是打开的，它会关闭；如果是关闭的，它会打开。它不负责将焦点移到侧边栏。
    vim.keymap.set('n', '<leader>e', '<Cmd>call VSCodeNotify("workbench.action.toggleSidebarVisibility")<CR>', { silent = true, desc = "切换侧边栏可见性" })

    -- <leader>fE / <leader>E: 在操作系统文件管理器中显示当前文件
    -- 执行 `revealFileInOS`，这会在 Finder (macOS) 或资源管理器 (Windows) 中定位并显示当前文件。
    -- 这两个快捷键功能完全相同，可以移除一个以避免冗余。
    vim.keymap.set('n', '<leader>fE', '<Cmd>call VSCodeNotify("revealFileInOS")<CR>', { silent = true, desc = "在 OS 文件管理器中显示" })
    vim.keymap.set('n', '<leader>E', '<Cmd>call VSCodeNotify("revealFileInOS")<CR>', { silent = true, desc = "在 OS 文件管理器中显示 (冗余)" })

    -- <leader>be: 显示所有已打开的编辑器列表
    -- 执行 `workbench.action.showAllEditors`，这会弹出一个快速选择列表，
    -- 列出所有当前打开的标签页（缓冲区），方便在它们之间快速跳转。
    vim.keymap.set('n', '<leader>be', '<Cmd>call VSCodeNotify("workbench.action.showAllEditors")<CR>', { silent = true, desc = "显示所有打开的编辑器" })

    -- <leader>ge: 打开源代码管理(Git)视图并聚焦
    -- 执行 `workbench.view.scm` 打开或切换到源代码管理视图，
    -- 然后执行 `workbench.action.focusSideBar` 将焦点移到侧边栏，方便查看 Git 状态或执行 Git 操作。
    vim.keymap.set('n', '<leader>ge', '<Cmd>call VSCodeNotify("workbench.view.scm")<CR><Cmd>call VSCodeNotify("workbench.action.focusSideBar")<CR>', { silent = true, desc = "打开并聚焦源代码管理" })
    
    -- 文件资源管理器快捷键 (仅在资源管理器中生效)
    -- 使用 autocmd 在进入文件浏览器缓冲区时应用特定的键位绑定
    do
        local explorer_augroup = vim.api.nvim_create_augroup("ExplorerKeymaps", { clear = true })

        vim.api.nvim_create_autocmd("BufEnter", {
            pattern = "*",
            group = explorer_augroup,
            callback = function(args)
                -- 通过检查 VSCode Neovim 插件设置的缓冲区变量来确定是否在文件浏览器中
                if vim.b[args.buf] and vim.b[args.buf].vscode_file_explorer then
                    local map = function(keys, command, desc)
                        vim.keymap.set('n', keys, command, { buffer = args.buf, silent = true, desc = desc })
                    end

                    -- 导航
                    map('<space>', '<Cmd>call VSCodeNotify("list.toggleExpand")<CR>', "切换节点展开/折叠")
                    map('<cr>',    '<Cmd>call VSCodeNotify("list.select")<CR>', "打开文件/目录")
                    map('<esc>',   '<Cmd>call VSCodeNotify("workbench.action.focusActiveEditorGroup")<CR>', "返回编辑器焦点")
                    map('q',       '<Cmd>call VSCodeNotify("workbench.action.toggleSidebarVisibility")<CR>', "关闭侧边栏")
                    map('i',       '<Cmd>call VSCodeNotify("list.focusUp")<CR>', "向上移动") -- 无效
                    map('k',       '<Cmd>call VSCodeNotify("list.focusDown")<CR>', "向下移动") -- 无效

                    -- 文件操作
                    map('a', '<Cmd>call VSCodeNotify("explorer.newFile")<CR>', "新建文件")
                    map('A', '<Cmd>call VSCodeNotify("explorer.newFolder")<CR>', "新建文件夹")
                    map('d', '<Cmd>call VSCodeNotify("deleteFile")<CR>', "删除文件")
                    map('r', '<Cmd>call VSCodeNotify("renameFile")<CR>', "重命名文件")
                    map('y', '<Cmd>call VSCodeNotify("filesExplorer.copy")<CR>', "复制文件")
                    map('x', '<Cmd>call VSCodeNotify("filesExplorer.cut")<CR>', "剪切文件")
                    map('p', '<Cmd>call VSCodeNotify("filesExplorer.paste")<CR>', "粘贴文件")
                    map('R', '<Cmd>call VSCodeNotify("workbench.files.action.refreshFilesExplorer")<CR>', "刷新资源管理器")
                end
            end
        })
    end
    
    -- Telescope 模糊查找快捷键
    vim.keymap.set('n', '<leader>ff', '<Cmd>call VSCodeNotify("workbench.action.quickOpen")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>fg', '<Cmd>call VSCodeNotify("workbench.action.findInFiles")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>fb', '<Cmd>call VSCodeNotify("workbench.action.showAllEditors")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>fh', '<Cmd>call VSCodeNotify("workbench.action.showCommands")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>fr', '<Cmd>call VSCodeNotify("workbench.action.openRecent")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>fc', '<Cmd>call VSCodeNotify("workbench.action.showCommands")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>fk', '<Cmd>call VSCodeNotify("workbench.action.openGlobalKeybindings")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>fs', '<Cmd>call VSCodeNotify("editor.action.addSelectionToNextFindMatch")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>fd', '<Cmd>call VSCodeNotify("workbench.actions.view.problems")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>ft', '<Cmd>call VSCodeNotify("workbench.action.gotoSymbol")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>fz', '<Cmd>call VSCodeNotify("workbench.action.findInFiles")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>rs', '<Cmd>call VSCodeNotify("workbench.action.findInFiles")<CR>', { silent = true })
    
    -- Telescope 导航快捷键 (在快速打开、搜索等对话框中使用)
    -- vim.keymap.set('n', '<C-i>', '<Cmd>call VSCodeNotify("workbench.action.quickOpenSelectPrevious")<CR>', { silent = true })  -- 向上移动选择
    -- vim.keymap.set('n', '<C-k>', '<Cmd>call VSCodeNotify("workbench.action.quickOpenSelectNext")<CR>', { silent = true })  -- 向下移动选择
    vim.keymap.set('n', '<C-n>', '<Cmd>call VSCodeNotify("workbench.action.quickOpenNavigateNext")<CR>', { silent = true })  -- 历史记录下一个
    vim.keymap.set('n', '<C-p>', '<Cmd>call VSCodeNotify("workbench.action.quickOpenNavigatePrevious")<CR>', { silent = true })  -- 历史记录上一个
    
    -- 在快速打开面板中的额外导航
    vim.keymap.set('n', '<Down>', '<Cmd>call VSCodeNotify("list.focusDown")<CR>', { silent = true })
    vim.keymap.set('n', '<Up>', '<Cmd>call VSCodeNotify("list.focusUp")<CR>', { silent = true })
    vim.keymap.set('n', '<CR>', '<Cmd>call VSCodeNotify("list.select")<CR>', { silent = true })
    
    -- 侧边栏切换
    vim.keymap.set('n', 'tt', '<Cmd>call VSCodeNotify("workbench.action.toggleSidebarVisibility")<CR>', { silent = true })
else
    -- 非 VSCode 环境的设置
    vim.o.showtabline = 2
    vim.wo.signcolumn = "yes"
    vim.wo.colorcolumn = "80"
end