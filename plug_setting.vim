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
""Plug 'ncm2/ncm2-jedi'
""Plug 'ncm2/ncm2-github'
"Plug 'ncm2/ncm2-bufword'
"Plug 'ncm2/ncm2-path'
"Plug 'ncm2/ncm2-match-highlight'
"Plug 'ncm2/ncm2-markdown-subscope'

" Language Server
"Plug 'autozimu/LanguageClient-neovim', {
    "\ 'branch': 'next',
    "\ 'do': 'bash install.sh',
    "\ }
let g:LanguageClient_serverCommands = {
\ 'rust': ['rust-analyzer'],
\ }


"" (Optional) Multi-entry selection UI.
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'Yggdroot/LeaderF', { 'do': './install.sh' }

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
" Plug 'brooth/far.vim'
Plug 'tmhedberg/SimpylFold'
Plug 'kassio/neoterm'
Plug 'vim-scripts/restore_view.vim'

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
" Rust analyzer
nmap <leader>a v<Plug>(coc-codeaction-selected)


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
"let g:indent_guides_guide_size = 1
"let g:indent_guides_start_level = 2
"let g:indent_guides_enable_on_vim_startup = 1
"let g:indent_guides_color_change_percent = 1
"silent! unmap <LEADER>ig
"autocmd WinEnter * silent! unmap <LEADER>ig


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
""let g:mkdp_echo_preview_url = 0
""let g:mkdp_browserfunc = ''
"let g:mkdp_preview_options = {
"    \ 'mkit': {},
""    \ 'katex': {},
"""    \ 'uml': {},
""    \ 'maid': {},
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
" nnoremap <silent> <LEADER>f :F  %<left><left>

" Testring my own plugin
"if !empty(glob('~/Github/vim-calc/vim-calc.vim'))
"  source ~/Github/vim-calc/vim-calc.vim
"endif
"map <LEADER>a :call Calc()<CR>

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

