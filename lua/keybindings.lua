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

-- 光标快速移动
-- 光标上移5行
map("n", "I", "5k", opt)
-- 光标下移5行
map("n", "K", "5j", opt)
-- 光标左移到行首
map("n", "J", "0", opt)
-- 光标右移到行尾
map("n", "L", "$", opt)

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

-- 光标键调整分屏窗口大小
map("", "<up>", ":res +5<CR>", opt)
map("", "<down>", ":res -5<CR>", opt)
map("", "<left>", ":vertical resize-5<CR>", opt)
map("", "<right>", ":vertical resize+5<CR>", opt)

-- 纵向横向调整两个分屏窗口的布局
map("", "sh", "<C-w>t<C-w>K", opt)
map("", "sv", "<C-w>t<C-w>H", opt)

-- 旋转屏幕
map("n", "srh", "<C-w>b<C-w>K", opt)
map("n", "srv", "<C-w>b<C-w>H", opt)

-- 空格+q 关闭当前使用的窗口
map("n", "<LEADER>q", "<C-w>j:q<CR>", opt)

-- 显示当前编辑的buffer的文件路径
map("n", "sp", "1<C-G>", opt)

-- 打开一个终端窗口
map("n", "<LEADER>/", ":set splitbelow<CR>:split<CR>:res +10<CR>:term<CR>", opt)
-- 退出终端模式
map("t", "<C-N>", "<C-\\><C-N>", opt) -- 注意这里使用了 \ 转义符
-- 关闭终端
map("t", "<C-O>", "<C-\\><C-N><C-O>", opt) -- 注意这里使用了 \ 转义符

-- 切换字符大小写
map("n", "<LEADER>sc", "~", opt)

-- 插件快捷键配置
-- nvimTree
--tt 打开nvimTree菜单
--o 打开关闭文件夹
--a 创建文件
--r 重命名
--x 剪切
--c 拷贝
--p 粘贴
--d 删除
map('n', 'tt', ':NvimTreeToggle<CR>', opt)






