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

" Include sub vim/nvim config files
source ~/.config/nvim/basic_setting.vim
"source ~/.config/nvim/plug_setting.vim

