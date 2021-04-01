" ===
" === Use Plug primary condition
" === Pyhton
" ===
let g:python_host_prog = '/usr/bin/python'
let g:python3_host_prog = '/usr/bin/python3'

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
" Theme 
Plug 'sheerun/vim-polyglot'
Plug 'pineapplegiant/spaceduck', { 'branch': 'main' }

" File navigation
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'ctrlpvim/ctrlp.vim', { 'on': 'CtrlP' } "Change hot key as ctrl + N like IDEA

"Taglist
Plug 'liuchengxu/vista.vim'

" Auto Complete
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'racer-rust/vim-racer'

"" (Optional) Multi-entry selection UI.
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'Yggdroot/LeaderF', { 'do': './install.sh' }

" Other visual enhancement
Plug 'itchyny/vim-cursorword'
" 启动界面
Plug 'mhinz/vim-startify'

" Git
"Plug 'rhysd/conflict-marker.vim'
Plug 'tpope/vim-fugitive'
Plug 'mhinz/vim-signify'
"Plug 'gisphm/vim-gitignore', { 'for': ['gitignore', 'vim-plug'] }

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
" Plug 'brooth/far.vim'
Plug 'kassio/neoterm'
"Plug 'vim-scrkshenoy/vim-signatureipts/restore_view.vim'

" Dependencies
Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'kana/vim-textobj-user'
Plug 'roxma/nvim-yarp'

"color
Plug 'connorholyday/vim-snazzy'

"Rust
Plug 'rust-lang/rust.vim'

"Plug 'autozimu/LanguageClient-neovim', {
"    \ 'branch': 'next',
"    \ 'do': 'bash install.sh',
"    \ }

"vim-plag end
call plug#end()


"open transparent and color
let g:SnazzyTransparent = 1

" ===
" === Dress up my vim
" ===
set termguicolors     " enable true colors support
let g:space_vim_transp_bg = 1

let g:lightline = {
  \     'active': {
  \         'left': [['mode', 'paste' ], ['readonly', 'filename', 'modified']],
  \         'right': [['lineinfo'], ['percent'], ['fileformat', 'fileencoding']]
  \     }
  \ }


" ===
" === Spaceduck theme
" ===
"if exists('+termguicolors')
  "let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  "let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  "set termguicolors
"endif

"colorscheme spaceduck

"let g:airline_theme = 'spaceduck'


" ===
" === CtrlP plug change hot key
" ===
let g:ctrlp_map = '<c-N>'

" ===
" === Vista.vim
" ===
noremap <LEADER>v :Vista!!<CR>
"noremap <c-t> :silent! Vista finder coc<CR>
let g:vista_icon_indent = ["╰─▸ ", "├─▸ "]
let g:vista_default_executive = 'coc'
let g:vista_fzf_preview = ['right:50%']
let g:vista#renderer#enable_icon = 1
let g:vista#renderer#icons = {
\   "function": "\uf794",
\   "variable": "\uf71b",
\  }

" ===
" === NNERDTreeMapOpenExplERDTree(项目结构树)
" === tt 显示项目结构树窗口
map tt :NERDTreeToggle<CR>
map th :help NERDTree-t<CR>

let NERDTreeMenuUp = "i"
let NERDTreeMenuDown = "k"
let NERDTreeMapOpenSplit = ""


" ===
" === FZF
" ===
"准确查找文件
"noremap <silent> <C-N> :Files<CR>
"LeaderF模糊查找文件
noremap <silent> <C-N> :Leaderf file<CR>


" ===
" === coc
" ===
" fix the most annoying bug that coc has
silent! au BufEnter,BufRead,BufNewFile * silent! unmap if
let g:coc_global_extensions = [
        \ 'coc-python', 
        \ 'coc-vimlsp', 
        \ 'coc-html', 
        \ 'coc-json', 
        \ 'coc-css', 
        \ 'coc-tsserver', 
        \ 'coc-yank', 
        \ 'coc-lists', 
        \ 'coc-gitignore', 
        \ 'coc-rls', 
        \ 'coc-rust-analyzer', 
        \ 'coc-tailwindcss']
" Useful commands
" 打开剪切板历史
nnoremap <silent> <space>y :<C-u>CocList -A --normal yank<cr>
" 列出定义列表
nmap <silent> gd <Plug>(coc-definition)
" 转至类型定义
nmap <silent> gy <Plug>(coc-type-definition)
" 代办事项清单
nmap <silent> gi <Plug>(coc-implementation)
" 列出参考列表
nmap <silent> gr <Plug>(coc-references)h
" 重命名变量名
nmap <leader>rn <Plug>(coc-rename)
" Rust analyzer
nmap <leader>a v<Plug>(coc-codeaction-selected)


" ===
" === vim-racer
" ===
set hidden
let g:racer_cmd = "/home/user/.cargo/bin/racer"
"augroup Racer
    "autocmd!
    "autocmd FileType rust nmap <buffer> gd         <Plug>(rust-def)
    "autocmd FileType rust nmap <buffer> gs         <Plug>(rust-def-split)
    "autocmd FileType rust nmap <buffer> gx         <Plug>(rust-def-vertical)
    "autocmd FileType rust nmap <buffer> gt         <Plug>(rust-def-tab)
    "autocmd FileType rust nmap <buffer> <leader>gd <Plug>(rust-doc)
    "autocmd FileType rust nmap <buffer> <leader>gD <Plug>(rust-doc-tab)
"augroup END

" ===
" === nerdcommenter 注释插件
" ===
" [count]<leader>cc |NERDCommenterComment|
" Comment out the current line or text selected in visual mode.
" [count]<leader>cu |NERDCommenterUncomment|
" Uncomments the selected line(s).


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
" === Python-syntax
" ===
let g:python_highlight_all = 1
" let g:python_slow_sync = 0


" ===
" === Taglist
" ===
"map <silent> T :TagbarOpenAutoClose<CR>


" ===
" === vim-table-mode
" ===
map <LEADER>tm :TableModeToggle<CR>


" ===
" === Goyo
" ===
map <LEADER>gy :Goyo<CR>

"
""" ===
""" === CtrlP
"" ===
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
" nnoremap <silent> <LEADER>f :F  %<left><left>


" ===================== End of Plugin Settings =====================

" ===
" === Necessary Commands to Execute
" ===
"clear search high light whem use vim or nvim open a file
exec "nohlsearch"

