return require('packer').startup(function()

    -------------------------- plugins -------------------------------------------

    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    -- alpha-nvim : 启动界面
    use {
        'goolord/alpha-nvim',
        config = function ()
            require'alpha'.setup(require'alpha.themes.dashboard'.config)
        end
    }

    -- nvim-tree : 文件目录树
    -- Usage:
    -- o 打开关闭文件夹
    -- a 创建文件
    -- r 重命名
    -- x 剪切
    -- c 拷贝
    -- p 粘贴
    -- d 删除
    use { 
        'kyazdani42/nvim-tree.lua',
        requires = {
            'kyazdani42/nvim-web-devicons'
        },
        tag = 'nightly'
    }

    -- bufferline : Tab UI
    use {
        'akinsho/bufferline.nvim',
        tag = "v2.*",
        requires = 'kyazdani42/nvim-web-devicons'
    }

    -- treesitter : 语法包
    -- Usage:
    -- :TSInstallInfo -- 查看已经安装的Language parser
    -- :TSInstall <language> -- 安装语言的parser
    -- zc 折叠代码 
    -- zo 展开代码 在keybindngs.lua中 map("", "<LEADER>o", "za", opt)
    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate'
    }

    -- Comment : 注释
    -- Usage:
    -- Normal 模式快捷键
    --   gcc 行注释
    --   gbc 块注释
    -- Visual 模式快捷键
    --   gc 行注释
    --   gb 块注释
    use 'numToStr/Comment.nvim'

    -- telescope : 查找 过滤 预览
    -- Ctrl + p : 文件查找
    -- <leader> + g : 在线查找
    -- <leader> + f : buffer查找
    use {
        'nvim-telescope/telescope.nvim',
        requires = {{'nvim-lua/plenary.nvim'}}
    }

    -- indent-blankline ： 缩进符号 scope边界
    use "lukas-reineke/indent-blankline.nvim"

    -------------------------- lsp -----------------------------------------------

    -- lspconfig ： neovim LSP 客户端的配置
    use {
        'neovim/nvim-lspconfig',
        'williamboman/nvim-lsp-installer'
    }
    -- nvim-cmp : 自动补全
    use 'hrsh7th/nvim-cmp' -- vsnip : 补全引擎
    -- 补全源
    use 'hrsh7th/cmp-nvim-lsp' -- { name = nvim_lsp }
    use 'hrsh7th/cmp-buffer'   -- { name = 'buffer' },
    use 'hrsh7th/cmp-path'     -- { name = 'path' }
    use 'hrsh7th/cmp-cmdline'  -- { name = 'cmdline' }
    use("hrsh7th/cmp-nvim-lsp-signature-help") -- { name = 'nvim_lsp_signature_help' }
    use 'hrsh7th/cmp-vsnip'    -- { name = 'vsnip' }

    -- Snippet 引擎
    use("hrsh7th/vim-vsnip")
    -- 常见编程语言代码段
    use 'rafamadriz/friendly-snippets'
    -- lspkind : UI增强
    use 'onsails/lspkind-nvim'
    use("tami5/lspsaga.nvim")
    -- 代码格式化
    use("mhartington/formatter.nvim")
    use({ "jose-elias-alvarez/null-ls.nvim", requires = "nvim-lua/plenary.nvim" })
    -- Lua 增强
    use("folke/lua-dev.nvim")
    -- JSON 增强
    use("b0o/schemastore.nvim")
    -- Rust 增强
    use("simrat39/rust-tools.nvim")

    -------------------------- colorscheme ---------------------------------------

    -- gruvbox
    --use {
    --    "ellisonleao/gruvbox.nvim",
    --    requires = { "rktjmp/lush.nvim" }
    --}

    -- zephyr
    --use 'glepnir/zephyr-nvim'
    
    -- nord
    --use 'shaunsingh/nord.nvim'
    
    -- onedark
    --use 'ful1e5/onedark.nvim'

    --nightfly
    use 'bluz71/vim-nightfly-guicolors'

    -------------------------- code ai ---------------------------------------
    
    -- codeium
    use 'Exafunction/codeium.vim'


end)
