-- VSCode Neovim 配置文件
-- 基于原始 basic.lua 和 keybindings.lua，但移除了插件依赖的功能

-- ============================================================================
-- 基础设置 (来自 basic.lua)
-- ============================================================================

-- 文件编码设置
vim.g.encoding = "UTF-8"
vim.o.fileencoding = "utf-8"

-- 光标移动时保留行数
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8

-- 行号设置
vim.wo.number = true
vim.wo.relativenumber = true

-- 高亮当前行
vim.wo.cursorline = true

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
vim.cmd([[autocmd BufReadPost * if line("'\""]) >= 1 && line("'\""]) <= line("$") | execute "normal! g`\"" | endif ]])

-- 剪贴板设置
vim.o.clipboard = "unnamed"

-- 复制后高亮
vim.api.nvim_create_autocmd({ "TextYankPost" }, {
    pattern = { "*" },
    callback = function()
        vim.hl.on_yank({
            timeout = 300,
        })
    end,
})

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
    vim.wo.signcolumn = "no"  -- VSCode 有自己的符号列
    vim.wo.colorcolumn = ""  -- VSCode 有自己的参考线
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
    
    -- Neo-tree 文件浏览器及相关视图快捷键

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