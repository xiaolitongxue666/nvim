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

    -- lspconfig
    use {
        'neovim/nvim-lspconfig',
        'williamboman/nvim-lsp-installer'
    }
    -- nvim-cmp
    use 'hrsh7th/cmp-nvim-lsp' -- { name = nvim_lsp }
    use 'hrsh7th/cmp-buffer'   -- { name = 'buffer' },
    use 'hrsh7th/cmp-path'     -- { name = 'path' }
    use 'hrsh7th/cmp-cmdline'  -- { name = 'cmdline' }
    use 'hrsh7th/nvim-cmp'
    -- vsnip
    use 'hrsh7th/cmp-vsnip'    -- { name = 'vsnip' }
    use 'hrsh7th/vim-vsnip'
    use 'rafamadriz/friendly-snippets'
    -- lspkind
    use 'onsails/lspkind-nvim'

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