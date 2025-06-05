-- hrsh7th/nvim-cmp
-- 一个功能强大的 Neovim 自动补全引擎
-- 用 Lua 编写的 Neovim 补全插件，支持多种补全源
-- 需要 Neovim 0.7 或更高版本

-- 官方文档: https://github.com/hrsh7th/nvim-cmp

return {
    {
        -- 在插入模式时加载，提升性能
        event = "InsertEnter",
        "hrsh7th/nvim-cmp",
        dependencies = {
            "neovim/nvim-lspconfig",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip", -- LuaSnip 的 cmp 源
        },
        config = function()
            -- nvim cmp
            -- 设置 nvim-cmp
            local has_words_before = function()
                unpack = unpack or table.unpack
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0
                        and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
            end

            local luasnip = require("luasnip")
            local cmp = require("cmp")
            local cmp_autopairs = require("nvim-autopairs.completion.cmp")
            cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
            cmp.setup({
                snippet = {
                    -- 必需 - 你必须指定一个代码片段引擎
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body) -- 适用于 `luasnip` 用户
                        -- require('snippy').expand_snippet(args.body) -- 适用于 `snippy` 用户
                        -- vim.fn["UltiSnips#Anon"](args.body) -- 适用于 `ultisnips` 用户
                    end,
                },
                
                -- 窗口样式配置
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                
                -- 性能优化配置
                performance = {
                    debounce = 60,
                    throttle = 30,
                    fetching_timeout = 500,
                },
                
                -- 补全行为配置
                completion = {
                    completeopt = 'menu,menuone,noinsert',
                },
                
                -- 确认行为配置
                confirm_opts = {
                    behavior = cmp.ConfirmBehavior.Replace,
                    select = false,
                },
                
                -- 实验性功能
                experimental = {
                    ghost_text = true,
                },
                
                -- 格式化配置
                formatting = {
                    format = function(entry, vim_item)
                        -- 设置补全项的来源标识
                        vim_item.menu = ({
                            nvim_lsp = "[LSP]",
                            luasnip = "[LuaSnip]",
                            buffer = "[Buffer]",
                            path = "[Path]",
                            cmdline = "[CMD]",
                        })[entry.source.name]
                        return vim_item
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                            -- 你可以用 expand_or_locally_jumpable() 替换 expand_or_jumpable() 调用
                            -- 这样你只会在代码片段区域内跳转
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),

                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-c>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }), -- 接受当前选中的项目。设置 `select` 为 `false` 只确认明确选中的项目
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp", priority = 1000 },
                    { name = "luasnip", priority = 750 }, -- LuaSnip 代码片段
                    { name = "buffer", priority = 500, keyword_length = 3 },
                    { name = "path", priority = 250 },
                    -- { name = 'ultisnips' }, -- 适用于 ultisnips 用户
                    -- { name = 'snippy' }, -- 适用于 snippy 用户
                }),
            })

            -- 为特定文件类型设置配置
            cmp.setup.filetype("gitcommit", {
                sources = cmp.config.sources({
                    { name = "cmp_git" }, -- 如果你安装了 `cmp_git` 源，可以指定它
                }, {
                    { name = "buffer" },
                }),
            })

            -- 为 `/` 和 `?` 使用缓冲区源（如果你启用了 `native_menu`，这将不再工作）
            cmp.setup.cmdline({ "/", "?" }, {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = "buffer" },
                },
            })

            -- 为 `:` 使用命令行和路径源（如果你启用了 `native_menu`，这将不再工作）
            cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = "path" },
                }, {
                    { name = "cmdline" },
                }),
            })
        end,
    },
}