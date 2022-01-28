return require('packer').startup(function()
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'


    -------------------------- plugins -------------------------------------------

    -- nvim-tree
    use {
        'kyazdani42/nvim-tree.lua',
        requires = 'kyazdani42/nvim-web-devicons'
    }

    -- bufferline
    use {
        'akinsho/bufferline.nvim',
        requires = 'kyazdani42/nvim-web-devicons'
    }

    -- treesitter
    -- :TSInstallInfo -- 查看已经安装的Language parser
    -- :TSInstall <language> -- 安装语言的parser
    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate'
    }

    -------------------------- lsp -----------------------------------------------

    -------------------------- colorscheme ---------------------------------------

    -- gruvbox
    use {
        "ellisonleao/gruvbox.nvim",
        requires = { "rktjmp/lush.nvim" }
    }
    -- zephyr
    use 'glepnir/zephyr-nvim'
    -- nord
    use 'shaunsingh/nord.nvim'
    -- onedark
    use 'ful1e5/onedark.nvim'

end)