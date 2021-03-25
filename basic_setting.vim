" ==============================
" === Editor Setup(编辑设置) ===
" ==============================
" ===
" === System(全局设置)
" ===
" copy form system clipboard(允许从系统剪切板拷贝数据)
set clipboard=unnamed
" let the color compatible to terminal(让陪着和终端兼容)
let &t_ut=' '
" automatic change working dir at now edit file's path(将工作目录自动跳转到编辑的文件路径)
set autochdir


" ===
" === Editor behavior(编辑操作)
" ===
"show line number(显示行号)
set number
"show relative line number(显示相对行号)
set relativenumber
"show cursor(显示光标)
set cursorline
" expand tab(扩展tab等价四个空格)
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
" apply the indentation of the current line to the next(当前行的缩进应用下一行)
set autoindent
" show the space at the end of line(显示行尾空格)
set list
" show the tab(显示tab符号，行首，行尾分别为以下符号)
set listchars=tab:▸\ ,trail:▫
" corsor distance form buffer edge some lines(光标到缓冲区边缘的距离)
set scrolloff=4
" allow for mappings includes 'Esc', while preserving zero timeout after pressing it manually(设置映射按键后的延迟)
set ttimeoutlen=0
set notimeout
" rember the cursor positon and other status when reopen file(在下一次打开文件的时候，记忆光标位置)
set viewoptions=cursor,folds,slash,unix
" automatic line break(自动换行)
set wrap
" set text width(设置文本宽度)
set tw=0
" expression whis is evaluated to obtain the proper indent for a line
set indentexpr=
" the kind of folding used for the current window
set foldmethod=indent

set foldlevel=99
set foldenable
set formatoptions-=tc

set splitright
set splitbelow
" enable mouse in vim
" set mouse=a
" if in insert, replace  or visual mode put a message on the last line swith to not show this line(各种模状态显示在窗口最下方的状态栏中)
set noshowmode
"show typed command(显示输入的命令，一般在：command 场景下显示)
set showcmd
" open command line comletion in enhanced mode(增强模式下打开代码补全)
set wildmenu
"ignore case the word during the search(搜索过程中忽略大小写)
set ignorecase
set smartcase
" Some testing features
" set shortmess+=c

" set inccommand=split
" should make scrolling faster(窗口滚动更快速)
set ttyfast
set lazyredraw

set visualbell

" high light search(搜索操作时，高亮关键词)
set hlsearch
"charter by charter high light the entered words during the search(搜索操作时，键入一个字符，高亮一个字符)
set incsearch 

" open the file cursor at the last edited position(重新打开文件，光标在上次编辑的位置
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif


" ===
" === Terminal Behavior
" ===
"
let g:neoterm_autoscroll = 1
"
autocmd TermOpen term://* startinsert
" tnoremap <C-N> <C-\><C-N>
" tnoremap <C-O> <C-\><C-N><C-O>
let g:terminal_color_0  = '#000000'
let g:terminal_color_1  = '#FF5555'
let g:terminal_color_2  = '#50FA7B'
let g:terminal_color_3  = '#F1FA8C'
let g:terminal_color_4  = '#BD93F9'
let g:terminal_color_5  = '#FF79C6'
let g:terminal_color_6  = '#8BE9FD'
let g:terminal_color_7  = '#BFBFBF'
let g:terminal_color_8  = '#4D4D4D'
let g:terminal_color_9  = '#FF6E67'
let g:terminal_color_10 = '#5AF78E'
let g:terminal_color_11 = '#F4F99D'
let g:terminal_color_12 = '#CAA9FA'
let g:terminal_color_13 = '#FF92D0'
let g:terminal_color_14 = '#9AEDFE'

" ===
" === Basic Mappings(基础键位映射)
" ===

" 设置空格键为LEADER
" Set <LEADER> as <SPACE>, ; as :
let mapleader=" "
"map ; :

" S 保存当前文件，Q 退出nvim
" Save & quit
map S :w<CR>
map Q :q<CR>

" 重载nvim配置文件
" Reload config file
map R :source ~/.config/nvim/init.vim<CR>

" 空格 + rc 打开nvim配置文件
" Open the vimrc file anytime
map <LEADER>rc :e ~/.config/nvim/init.vim<CR>

" 使能nvim启动运行界面
" https://github.com/mhinz/vim-startify
" Open Startify
map <LEADER>st :Startify<CR>

" Undo operations
" Just type 'u' do undo
" Just type <C-u> do undo in Insert mode

" Redo operations
" Just type <C-r> do redo

" 普通模式和visual模式插入按键重映射
" Insert Key
noremap h i
noremap H I
" Visual mode key map
vnoremap h i
vnoremap H I

" Y 拷贝光标当前位置到行尾的字符串
" Make Y to copy till the end of the line
nnoremap Y y$

" Y 拷贝光标当前位置到行为的字符串到系统剪切板
" Copy to system clipboard
vnoremap Y :w !xclip -i -sel c<CR>

" Indentation
" nnoremap < <<
" nnoremap > >>

" n 跳转到下一个搜索结果
" N 跳转到上一个搜索结果
" 空格+回车 取消搜索高亮显示
" Jump to search result next one
noremap n nzz
" Jumo to search result last one
noremap N Nzz
" Clear all search high light
noremap <LEADER><CR> :nohlsearch<CR>

" 显示相邻的重复字符或者单词
" Adjacent duplicate words
noremap <LEADER>dw /\(\<\w\+\>\)\_s*\1

" 将四个空格转换为制表符
" Space to Tab
" nnoremap <LEADER>tt :%s/    /\t/g
" vnoremap <LEADER>tt :s/    /\t/g

" 折叠代码
" Folding
map <silent> <LEADER>o za

" Open up lazygit
" noremap \g :term lazygit<CR>
" noremap <c-g> :term lazygit<CR>

" ===
" === Cursor Movement(光标移动)
" ===
"
" New cursor movement (the default arrow keys are used for resizing windows)
"     ^
"     i
" < j   l >
"     k
"     v
noremap <silent> i k
noremap <silent> k j
noremap <silent> j h
noremap <silent> l l

" 光标快速移动
" I/K keys for 5 times i/k (faster navigation)
noremap <silent> I 5k
noremap <silent> K 5j
" J/L keys for 5 times j/l (faster navigation)
"noremap J 5h
"noremap L 5l
" J key: go to the start of the line
noremap <silent> J 0
" L key: go to the end of the line
noremap <silent> L $

" 将视角上下移动五行而不移动光标
" Ctrl + I or K will move up/down the view port without moving the cursor
noremap <LEADER>mi 5<C-y>
noremap <LEADER>mk 5<C-e>

" ===
" === Window management(窗口管理)
" ===
" 空格+ i k j l 在不同分屏窗口之间移动
" Use <space> + new arrow keys for moving the cursor around windows
map <LEADER>i <C-w>k
map <LEADER>k <C-w>j
map <LEADER>j <C-w>h
map <LEADER>l <C-w>l

" Disabling the default s key
noremap s <nop>

" split the screens to up (horizontal), down (horizontal), left (vertical), right (vertical)
" s+ i/k/j/l 创建分屏窗口
noremap si :set nosplitbelow<CR>:split<CR>:set splitbelow<CR>
noremap sk :set splitbelow<CR>:split<CR>
noremap sj :set nosplitright<CR>:vsplit<CR>:set splitright<CR>
noremap sl :set splitright<CR>:vsplit<CR>

"光标键调整分屏窗口大小
" Resize splits with arrow keys
map <up> :res +5<CR>
map <down> :res -5<CR>
map <left> :vertical resize-5<CR>
map <right> :vertical resize+5<CR>

" 纵向横向调整两个分屏窗口的布局
" Place the two screens up and down
map sh <C-w>t<C-w>K
" Place the two screens side by side
map sv <C-w>t<C-w>H

" 旋转屏幕
" Rotate screens
noremap srh <C-w>b<C-w>K
noremap srv <C-w>b<C-w>H

" 空格+q 关闭当前使用的窗口
" Press <SPACE> + q to close the window below the current window
noremap <LEADER>q <C-w>j:q<CR>

" ===
" === Other useful stuff
" ===
" sp to show the current buffer file path
nnoremap sp 1<C-G>

" Opening a terminal window(打开一个终端窗口)
" map <LEADER>/ :set splitbelow<CR>:sp<CR>:term<CR>
noremap <LEADER>/ :term<CR>

" Press ` to change case (instead of ~)
noremap <LEADER>sc ~











