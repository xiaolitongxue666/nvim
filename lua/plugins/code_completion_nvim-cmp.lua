return {
    {
        event = "VeryLazy",
        "hrsh7th/nvim-cmp",
        dependencies = {
            "neovim/nvim-lspconfig",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "hrsh7th/nvim-cmp",
            "L3MON4D3/LuaSnip",
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
                window = {
                    -- completion = cmp.config.window.bordered(),
                    -- documentation = cmp.config.window.bordered(),
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
                    { name = "nvim_lsp" },
                    { name = "luasnip" }, -- 适用于 luasnip 用户
                    -- { name = 'ultisnips' }, -- 适用于 ultisnips 用户
                    -- { name = 'snippy' }, -- 适用于 snippy 用户
                }, {
                    { name = "buffer" },
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