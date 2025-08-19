-- leader key 为空格
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 基础快捷键配置

-- 本地变量 lua 特性, 类似C的宏用于简写默认函数
local map = vim.api.nvim_set_keymap
local opt = {
    noremap = true,
    silent = true
}

-- S 保存当前文件，Q 退出nvim
map("", "S", ":w<CR>", opt)
map("", "Q", ":q<CR>", opt)

-- 重载nvim配置文件
map("", "R", ":source ~/.config/nvim/init.vim<CR>", opt)

-- 空格 + rc 打开nvim配置文件
map("", "<LEADER>rc", ":e ~/.config/nvim/init.vim<CR>", opt)

-- 普通模式和visual模式插入按键重映射
map("n", "h", "i", opt)
map("n", "H", "I", opt)
map("v", "h", "i", opt)
map("v", "H", ":I", opt)

-- n 跳转到下一个搜索结果
-- N 跳转到上一个搜索结果
-- 空格+回车 取消搜索高亮显示
map("n", "n", "nzz", opt)
map("n", "N", "Nzz", opt)
map("n", "<LEADER><CR>", ":nohlsearch<CR>", opt)

-- 显示相邻的重复字符或者单词
--map("n", "<<LEADER>dw", "/\(\<\w\+\>\)\_s*\1", opt) -- error

-- 折叠代码
map("", "<LEADER>o", "za", opt)

-- 光标常规移动
--     ^
--     i
-- < j   l >
--     k
--     v
map("n", "i", "k", opt)
map("n", "k", "j", opt)
map("n", "j", "h", opt)
map("n", "l", "l", opt)

-- v 模式下光标常规移动
map("v", "i", "k", opt)
map("v", "k", "j", opt)
map("v", "j", "h", opt)
map("v", "l", "l", opt)

-- 光标快速移动
-- 光标上移5行
map("n", "I", "5k", opt)
-- 光标下移5行
map("n", "K", "5j", opt)
-- 光标左移到单词开头
map("n", "J", "b", opt)
-- 光标右移到单词开头
map("n", "L", "w", opt)
-- 跳转到行尾
map("n", "E", "$", opt)

-- v 模式下光标快速移动
-- 光标上移5行
map("v", "I", "5k", opt)
-- 光标下移5行
map("v", "K", "5j", opt)
-- 光标左移到单词开头
map("v", "J", "b", opt)
-- 光标右移到单词开头
map("v", "L", "w", opt)

-- 窗口管理
-- s+ i/k/j/l 创建分屏窗口
map("", "si", ":set nosplitbelow<CR>:split<CR>:set splitbelow<CR>", opt)
map("", "sk", ":set splitbelow<CR>:split<CR>", opt)
map("", "sj", ":set nosplitright<CR>:vsplit<CR>:set splitright<CR>", opt)
map("", "sl", ":set splitright<CR>:vsplit<CR>", opt)

-- 空格+ i k j l 在不同分屏窗口之间移动
map("n", "<LEADER>i", "<C-w>k", opt)
map("n", "<LEADER>k", "<C-w>j", opt)
map("n", "<LEADER>j", "<C-w>h", opt)
map("n", "<LEADER>l", "<C-w>l", opt)

-- 光标键调整分屏窗口大小（已移至智能窗口控制模块）
-- map("", "<up>", ":res +5<CR>", opt)
-- map("", "<down>", ":res -5<CR>", opt)
-- map("", "<left>", ":vertical resize-5<CR>", opt)
-- map("", "<right>", ":vertical resize+5<CR>", opt)

-- 纵向横向调整两个分屏窗口的布局
map("", "sh", "<C-w>t<C-w>K", opt)
map("", "sv", "<C-w>t<C-w>H", opt)

-- 旋转屏幕
map("n", "srh", "<C-w>b<C-w>K", opt)
map("n", "srv", "<C-w>b<C-w>H", opt)

-- 空格+q 关闭当前使用的窗口
map("n", "<LEADER>q", ":q<CR>", opt)

-- 空格+Q 直接退出Neovim（保存所有文件）
map("n", "<LEADER>Q", ":wqa<CR>", opt)

-- 空格+b 关闭当前使用的buffer
map("n", "<LEADER>b", ":b #<CR>:bd #<CR>", opt)

-- 显示当前编辑的buffer的文件路径
map("n", "sp", "1<C-G>", opt)

-- 打开一个终端窗口
map("n", "<LEADER>/", ":set splitbelow<CR>:split<CR>:res +10<CR>:term<CR>", opt)
-- 退出终端模式
map("t", "<C-N>", "<C-\\><C-N>", opt) -- 注意这里使用了 \ 转义符
-- 关闭终端
map("t", "<C-O>", "<C-\\><C-N><C-O>", opt) -- 注意这里使用了 \ 转义符
-- 或者 直接在 终端模式下 输入 Ctrl + d 关闭终端

-- 切换字符大小写
map("n", "<LEADER>sc", "~", opt)

-- 返回到上一个位置
map("n", "<A-[>", "<C-i>", opt)

-- 返回到下一个位置
map("n", "<A-]>", "<C-o>", opt)

-- 注意：插件相关的键位映射已移至各自的插件配置文件中
-- 例如：telescope 的键位在 lua/plugins/finder_telescope.lua
--      neo-tree 的键位在 lua/plugins/ui_file_explorer_neo-tree.lua
--      LSP 的键位在 lua/plugins/lsp_server_nvim-lspconfig.lua





