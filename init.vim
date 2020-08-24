"   _  __ _                __    _    _   __                _
"  | |/ /(_)___ _____     / /   (_)  / | / /__  ____ _   __(_)___ ___
"  |   // / __ `/ __ \   / /   / /  /  |/ / _ \/ __ \ | / / / __ `__ \
" /   |/ / /_/ / /_/ /  / /___/ /  / /|  /  __/ /_/ / |/ / / / / / / /
"/_/|_/_/\__,_/\____/  /_____/_/  /_/ |_/\___/\____/|___/_/_/ /_/ /_/

" ===
" === Auto download vim-plug, if you download fal, 
" === copy plug.vim in this repository into right place
" === 自动下载vim-plg插件管理软件,
" === 如果下载失败，可以拷贝本仓库中的plug.vim文件到目标地址
" ===
if empty(glob('~/.config/nvim/autoload/plug.vim'))
        silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
                \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        autocmd VimEnter * PlugInstall --sync | source $MYVIMRC"
endif


" ===
" === CheckHealth Resolve Solution(CheckHealth 报错解决办法)
" ===
" === Pyhton
" ===
let g:python_host_prog = '/usr/bin/python'
let g:python3_host_prog = '/usr/local/bin/python3'


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
" noremap l u
" Undo in Insert mode
" inoremap <C-l> <C-u>

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

" Space to Tab
" nnoremap <LEADER>tt :%s/    /\t/g
" vnoremap <LEADER>tt :s/    /\t/g

" Folding
"map <silent> <LEADER>o za

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

" Change to next file buffer(切换到下一个已打开文件)
noremap <C-w> :bn<CR>

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

" Faster in-line navigation
"noremap W 5w
"noremap B 5b
" set h (same as n, cursor left) to 'end of word'
"noremap h e

" Ctrl + I or K will move up/down the view port without moving the cursor
noremap <C-I> 5<C-y>
noremap <C-K> 5<C-e>
"inoremap <C-I> <Esc>5<C-y>a
"inoremap <C-K> <Esc>5<C-e>a

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
" map sl :set splitright<CR>:vsplit<CR>
" map si :set nosplitbelow<CR>:split<CR>
" map sk :set splitbelow<CR>:split<CR>
" map sj :set nosplitright<CR>:vsplit<CR>
" map sl :set splitright<CR>:vsplit<CR>
" s+ i/k/j/l 创建分屏窗口
noremap si :set nosplitbelow<CR>:split<CR>:set splitbelow<CR>
noremap sk :set splitbelow<CR>:split<CR>
noremap sj :set nosplitright<CR>:vsplit<CR>:set splitright<CR>
noremap sl :set splitright<CR>:vsplit<CR>

"光标键调整分屏窗口大小
" Resize splits with arrow keys
map <up> :res +5<CR>
map <down> :res -5<CR>
map <left> :vertical resize+5<CR>
map <right> :vertical resize-5<CR>

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
" === Tab management(标签页管理)
" ===
" Create a new tab with tu(tu 新建一个标签页)
map tu :tabe<CR>
" Move around tabs with tj and tl(tj tl 在标签页间左右移动)
map tj :-tabnext<CR>
map tl :+tabnext<CR>
" Move the tabs with tmj and tml(tmj tml 左右移动标签页)
map tmj :-tabmove<CR>
map tml :+tabmove<CR>

" ===
" === Markdown Settings
" ===
" Snippets
" source ~/.config/nvim/md-snippets.vim
" " auto spell
" autocmd BufRead,BufNewFile *.md setlocal spell

" ===
" === Other useful stuff
" ===
" \p to show the current buffer file path
" nnoremap \p 1<C-G>

" Move the next character to the end of the line with ctrl+9
" inoremap <C-u> <ESC>lx$p

" Opening a terminal window(打开一个终端窗口)
" map <LEADER>/ :set splitbelow<CR>:sp<CR>:term<CR>
noremap <LEADER>/ :term<CR>

" Press space twice to jump to the next '<++>' and edit it
"noremap <LEADER><LEADER> <Esc>/<++><CR>:nohlsearch<CR>c4i

" Spelling Check with <space>sc
"noremap <LEADER>sc :set spell!<CR>

" Press ` to change case (instead of ~)
"noremap ` ~

"noremap <C-c> zz

" Auto change directory to current dir
"autocmd BufEnter * silent! lcd %:p:h

" Call figlet
"map tx :r !figlet

" Compile function
"map r :call CompileRunGcc()<CR>
"func! CompileRunGcc()
  "exec "w"
  "if &filetype == 'c'
    "exec "!g++ % -o %<"
    "exec "!time ./%<"
  "elseif &filetype == 'cpp'
    "exec "!g++ % -o %<"
    "exec "!time ./%<"
  "elseif &filetype == 'java'
    "exec "!javac %"
    "exec "!time java %<"
  "elseif &filetype == 'sh'
    ":!time bash %
  "elseif &filetype == 'python'
    "set splitright
    ":vsp
    ":vertical resize-20
    ":term python3 %
  "elseif &filetype == 'html'
    "exec "!chromium % &"
  "elseif &filetype == 'markdown'
    "exec "MarkdownPreview"
  "endif
"endfunc

"map R :call CompileBuildrrr()<CR>
"func! CompileBuildrrr()
  "exec "w"
  "if &filetype == 'vim'
    "exec "source $MYVIMRC"
  "elseif &filetype == 'markdown'
    "exec "echo"
  "endif
"endfunc


" ===
" === Install Plugins with Vim-Plug(插件管理)
" === In normal mode type "PlugInstall" to install plugs
" ===
"vim-plug begin
call plug#begin('~/.config/nvim')

"Pretty Dress
"status bar
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
"show the list of buffers in the command bar
Plug 'bling/vim-bufferline'

" File navigation
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'ctrlpvim/ctrlp.vim', { 'on': 'CtrlP' }

" Taglist
Plug 'majutsushi/tagbar', { 'on': 'TagbarOpenAutoClose' }

" Error checking
"Plug 'w0rp/ale'

" Auto Complete
"Plug 'Valloric/YouCompleteMe'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

"Plug 'davidhalter/jedi-vim'
"Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
"Plug 'ncm2/ncm2'
"Plug 'ncm2/ncm2-jedi'
"Plug 'ncm2/ncm2-github'
"Plug 'ncm2/ncm2-bufword'
"Plug 'ncm2/ncm2-path'
"Plug 'ncm2/ncm2-match-highlight'
"Plug 'ncm2/ncm2-markdown-subscope'

" Language Server
"Plug 'autozimu/LanguageClient-neovim', {
    "\ 'branch': 'next',
    "\ 'do': 'bash install.sh',
    "\ }

"" (Optional) Multi-entry selection UI.
Plug 'junegunn/fzf'

" Undo Tree
Plug 'mbbill/undotree/'

" Other visual enhancement
Plug 'nathanaelkane/vim-indent-guides'
"Plug 'itchyny/vim-cursorword'
"Plug 'tmhedberg/SimpylFold'
Plug 'mhinz/vim-startify'

" Git
Plug 'rhysd/conflict-marker.vim'
Plug 'tpope/vim-fugitive'
Plug 'mhinz/vim-signify'
Plug 'gisphm/vim-gitignore', { 'for': ['gitignore', 'vim-plug'] }

" HTML, CSS, JavaScript, PHP, JSON, etc.
Plug 'elzr/vim-json'
Plug 'hail2u/vim-css3-syntax'
Plug 'spf13/PIV', { 'for' :['php', 'vim-plug'] }
Plug 'gko/vim-coloresque', { 'for': ['vim-plug', 'php', 'html', 'javascript', 'css', 'less'] }
Plug 'pangloss/vim-javascript', { 'for' :['javascript', 'vim-plug'] }
Plug 'mattn/emmet-vim'

" Python
Plug 'vim-scripts/indentpython.vim', { 'for' :['python', 'vim-plug'] }
Plug 'numirias/semshi', { 'do': ':UpdateRemotePlugins' }

" Markdown
"Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install_sync() }, 'for' :['markdown', 'vim-plug'] }
"Plug 'dhruvasagar/vim-table-mode', { 'on': 'TableModeToggle' }

" For general writing
Plug 'reedes/vim-wordy'
Plug 'ron89/thesaurus_query.vim'

" Bookmarks
Plug 'kshenoy/vim-signature'

" Other useful utilities
Plug 'jiangmiao/auto-pairs'
Plug 'terryma/vim-multiple-cursors'
Plug 'junegunn/goyo.vim' " distraction free writing mode
Plug 'tpope/vim-surround' " type ysks' to wrap the word with '' or type cs'` to change 'word' to `word`
Plug 'godlygeek/tabular' " type ;Tabularize /= to align the =
Plug 'gcmt/wildfire.vim' " in Visual mode, type i' to select all text in '', or type i) i] i} ip
Plug 'scrooloose/nerdcommenter' " in <space>cc to comment a line
"Plug 'yuttie/comfortable-motion.vim'
Plug 'brooth/far.vim'
Plug 'tmhedberg/SimpylFold'
Plug 'kassio/neoterm'
Plug 'vim-scripts/restore_view.vim'

" Dependencies
Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'kana/vim-textobj-user'
Plug 'roxma/nvim-yarp'

"color
Plug 'connorholyday/vim-snazzy'

"vim-plag end
call plug#end()

" ===
" === Create a _machine_specific.vim file to adjust machine specific stuff, like python interpreter location
" ===
"let has_machine_specific_file = 1
"if empty(glob('~/.config/nvim/_machine_specific.vim'))
"  let has_machine_specific_file = 0
"  silent! exec "!cp ~/.config/nvim/default_configs/_machine_specific_default.vim ~/.config/nvim/_machine_specific.vim"
"endif
"source ~/.config/nvim/_machine_specific.vim

"open transparent and color
let g:SnazzyTransparent = 1

" ===
" === Dress up my vim
" ===
"map <LEADER>c1 :set background=dark<CR>:colorscheme snazzy<CR>:AirlineTheme dracula<CR>
"map <LEADER>c2 :set background=light<CR>:colorscheme ayu<CR>:AirlineTheme ayu_light<CR>

set termguicolors     " enable true colors support
"colorscheme snazzy
let g:space_vim_transp_bg = 1
"set background=dark
"colorscheme space_vim_theme
"let g:airline_theme='dracula'

let g:lightline = {
  \     'active': {
  \         'left': [['mode', 'paste' ], ['readonly', 'filename', 'modified']],
  \         'right': [['lineinfo'], ['percent'], ['fileformat', 'fileencoding']]
  \     }
  \ }

" set statusline+=%#warningmsg#
" set statusline+=%{SyntasticStatuslineFlag()}
" set statusline+=%*

" ===
" === NNERDTreeMapOpenExplERDTree(项目结构树)
" === tt 显示项目结构树窗口
map tt :NERDTreeToggle<CR>
map th :help NERDTree-t<CR>

let NERDTreeMenuUp = "i"
let NERDTreeMenuDown = "k"
let NERDTreeMapOpenSplit = ""


"let NERDTReeMenuUp = "i"
"let NERDTreeMenuDown = "k"
"let NERDTreeMapOpenExpl = ""
"let NERDTreeMapUpdir = ""
"let NERDTreeMapUpdirKeepOpen = "l"
"let NERDTreeMapOpenSplit = ""
"let NERDTreeOpenVSplit = ""
"let NERDTreeMapActivateNode = ""
"let NERDTreeMapOpenInTab = "o"
"let NERDTreeMapPreview = ""
"let NERDTreeMapCloseDir = "n"
"let NERDTreeMapChangeRoot = "y"


" ===
" === coc
" ===
" fix the most annoying bug that coc has
silent! au BufEnter,BufRead,BufNewFile * silent! unmap if
let g:coc_global_extensions = ['coc-python', 'coc-vimlsp', 'coc-html', 'coc-json', 'coc-css', 'coc-tsserver', 'coc-yank', 'coc-lists', 'coc-gitignore', 'coc-vimlsp', 'coc-tailwindcss']
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}
" use <tab> for trigger completion and navigate to the next complete item
function! s:check_back_space() abort
	let col = col('.') - 1
	return !col || getline('.')[col - 1]	=~ '\s'
endfunction
inoremap <silent><expr> <Tab>
			\ pumvisible() ? "\<C-n>" :
			\ <SID>check_back_space() ? "\<Tab>" :
			\ coc#refresh()
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <silent><expr> <c-space> coc#refresh()
" Useful commands
nnoremap <silent> <space>y :<C-u>CocList -A --normal yank<cr>
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <leader>rn <Plug>(coc-rename)

" Change completion windows background
hi Pmenu ctermfg=0 ctermbg=6 guibg=#444444
hi PmenuSel ctermfg=7 ctermbg=4 guibg=#555555 guifg=#ffffff

" ==
" == NERDTree-git
" ==
let g:NERDTreeIndicatorMapCustom = {
    \ "Modified"  : "?",
    \ "Staged"    : "?",
    \ "Untracked" : "?",
    \ "Renamed"   : "?",
    \ "Unmerged"  : "?",
    \ "Deleted"   : "?",
    \ "Dirty"     : "?",
    \ "Clean"     : "??",
    \ "Unknown"   : "?"
    \ }

" ===
" === NCM2
" ===
"inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
"inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
"inoremap <expr> <CR> (pumvisible() ? "\<c-y>\<cr>": "\<CR>")
"autocmd BufEnter * call ncm2#enable_for_buffer()
"set completeopt=noinsert,menuone,noselect

"Add by xiaoli
"let g:python3_host_prog=/usr/bin/python3
"let g:ruby_host_prog = '/home/xiaoli/.gem/ruby/2.6.0/bin/neovim-ruby-host.ruby.2.6'

"let ncm2#popup_delay = 5
"let g:ncm2#matcher = "substrfuzzy"
"let g:ncm2_jedi#python_version = 3
"let g:ncm2#match_highlight = 'bold'

"let g:jedi#auto_initialization = 1
""let g:jedi#completion_enabled = 0
""let g:jedi#auto_vim_configuration = 0
""let g:jedi#smart_auto_mapping = 0
"let g:jedi#popup_on_dot = 1
"let g:jedi#completion_command = ""
"let g:jedi#show_call_signatures = "1"


" ===
" === vim-indent-guide
" ===
let g:indent_guides_guide_size = 1
let g:indent_guides_start_level = 2
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_color_change_percent = 1
silent! unmap <LEADER>ig
autocmd WinEnter * silent! unmap <LEADER>ig


" ===
" === some error checking
" ===



" ===
" === MarkdownPreview
" ===
"let g:mkdp_auto_start = 0
"let g:mkdp_auto_close = 1
"let g:mkdp_refresh_slow = 0
"let g:mkdp_command_for_global = 0
"let g:mkdp_open_to_the_world = 0
"let g:mkdp_open_ip = ''
"let g:mkdp_browser = 'chromium'
"let g:mkdp_echo_preview_url = 0
"let g:mkdp_browserfunc = ''
"let g:mkdp_preview_options = {
"    \ 'mkit': {},
"    \ 'katex': {},
"    \ 'uml': {},
"    \ 'maid': {},
"    \ 'disable_sync_scroll': 0,
"    \ 'sync_scroll_type': 'middle',
"    \ 'hide_yaml_meta': 1
"    \ }
"let g:mkdp_markdown_css = ''
"let g:mkdp_highlight_css = ''
"let g:mkdp_port = ''
"let g:mkdp_page_title = '?${name}?'
"
"
" ===
" === Python-syntax
" ===
let g:python_highlight_all = 1
" let g:python_slow_sync = 0


" ===
" === Taglist
" ===
map <silent> T :TagbarOpenAutoClose<CR>


" ===
" === vim-table-mode
" ===
map <LEADER>tm :TableModeToggle<CR>


" ===
" === Goyo
" ===
map <LEADER>gy :Goyo<CR>


" ===
" === CtrlP
" ===
map <C-p> :CtrlP<CR>
let g:ctrlp_prompt_mappings = {
  \ 'PrtSelectMove("j")':   ['<c-e>', '<down>'],
  \ 'PrtSelectMove("k")':   ['<c-u>', '<up>'],
  \ }


" ===
" === vim-signiture
" ===
let g:SignatureMap = {
        \ 'Leader'             :  "m",
        \ 'PlaceNextMark'      :  "m,",
        \ 'ToggleMarkAtLine'   :  "m.",
        \ 'PurgeMarksAtLine'   :  "dm-",
        \ 'DeleteMark'         :  "dm",
        \ 'PurgeMarks'         :  "dm/",
        \ 'PurgeMarkers'       :  "dm?",
        \ 'GotoNextLineAlpha'  :  "m<LEADER>",
        \ 'GotoPrevLineAlpha'  :  "",
        \ 'GotoNextSpotAlpha'  :  "m<LEADER>",
        \ 'GotoPrevSpotAlpha'  :  "",
        \ 'GotoNextLineByPos'  :  "",
        \ 'GotoPrevLineByPos'  :  "",
        \ 'GotoNextSpotByPos'  :  "mn",
        \ 'GotoPrevSpotByPos'  :  "mp",
        \ 'GotoNextMarker'     :  "",
        \ 'GotoPrevMarker'     :  "",
        \ 'GotoNextMarkerAny'  :  "",
        \ 'GotoPrevMarkerAny'  :  "",
        \ 'ListLocalMarks'     :  "m/",
        \ 'ListLocalMarkers'   :  "m?"
        \ }


" ===
" === Undotree
" ===
" let g:undotree_DiffAutoOpen = 0
" map L :UndotreeToggle<CR>

" ==
" == vim-multiple-cursor
" ==
let g:multi_cursor_use_default_mapping=0
let g:multi_cursor_start_word_key      = '<c-k>'
let g:multi_cursor_select_all_word_key = '<a-k>'
let g:multi_cursor_start_key           = 'g<c-k>'
let g:multi_cursor_select_all_key      = 'g<a-k>'
let g:multi_cursor_next_key            = '<c-k>'
let g:multi_cursor_prev_key            = '<c-p>'
let g:multi_cursor_skip_key            = '<C-x>'
let g:multi_cursor_quit_key            = '<Esc>'


" My snippits
source ~/.config/nvim/snippits.vim

" comfortable-motion
"nnoremap <silent> <C-e> :call comfortable_motion#flick(50)<CR>
"nnoremap <silent> <C-u> :call comfortable_motion#flick(-50)<CR>
"let g:comfortable_motion_no_default_key_mappings = 1
"let g:comfortable_motion_interval = 1


" Startify
let g:startify_lists = [
      \ { 'type': 'files',     'header': ['   MRU']            },
      \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      },
      \ { 'type': 'commands',  'header': ['   Commands']       },
      \ ]

" Far.vim
nnoremap <silent> <LEADER>f :F  %<left><left>

" Testring my own plugin
if !empty(glob('~/Github/vim-calc/vim-calc.vim'))
  source ~/Github/vim-calc/vim-calc.vim
endif
map <LEADER>a :call Calc()<CR>

let g:user_emmet_leader_key='<C-f>'
" Open the _machine_specific.vim file if it has just been created
"if has_machine_specific_file == 0
"  exec "e ~/.config/nvim/_machine_specific.vim"
"endif


" ===================== End of Plugin Settings =====================

" ===
" === Necessary Commands to Execute
" ===
"clear search high light whem use vim or nvim open a file
exec "nohlsearch"

