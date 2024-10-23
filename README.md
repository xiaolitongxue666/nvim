# This repo is no longer maintained.

# Neovim config

## Install and config neovim
- MacOS:
 ```
 brew update neovim
 cd  ~/.config/
 git clone <this_repo_url>
 ```
 
- CentOS:
 ```
 yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
 yum install -y neovim python3-neovim
 cd  ~/.config/
 git clone <this_repo_url>
 ```

- Windows10:
```
choco install neovim
cd ~/AppData/Local/
git clone <this_repo_url>
```

## Install Packer Plug Manager
- Unix and Linux
 ```
 git clone --depth 1 https://github.com/wbthomason/packer.nvim \ 
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
 ```

- Windows10
```
git clone https://github.com/wbthomason/packer.nvim "$env:LOCALAPPDATA\nvim-data\site\pack\packer\start\packer.nvim"
```  

## Install telescope
 - External dependencies
    riggrep : https://github.com/BurntSushi/ripgrep
    fd      : https://github.com/sharkdp/fd

## Tricks
- 'R' : 刷新左侧文件树

- 'Ctrl + R' : redo操作

