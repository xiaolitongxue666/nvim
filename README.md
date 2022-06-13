# Neovim config

# Update Neovim
- MacOS:
 ```
 brew update neovim
 ```
 
- CentOS:
 ```
 yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
 yum install -y neovim python3-neovim
 ```

# Install Packer Plug Manager
 ```
 git clone --depth 1 https://github.com/wbthomason/packer.nvim \ 
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
 ```
 
# Install Copilot
 https://github.com/github/copilot.vim

 - Install
 ```
 git clone https://github.com/github/copilot.vim.git \
 ~/.config/nvim/pack/github/start/copilot.vim
 ```
    
 - Config
 ```
 :help Copilot
 :Copilot setup
 :Copilot status
 :Copilot enable
 :Copilot signout
 ```
    
# Install telescope
 - External dependencies
    riggrep : https://github.com/BurntSushi/ripgrep
    fd      : https://github.com/sharkdp/fd

# Tricks
- R 刷新文件树

- Ctrl + R redo操作

