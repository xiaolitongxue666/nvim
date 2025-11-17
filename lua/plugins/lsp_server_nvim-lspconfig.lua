-- Neovim 内置 LSP 客户端的快速配置
-- 提供各种语言服务器的预配置设置

-- https://github.com/neovim/nvim-lspconfig

-- 统一处理 schemastore 模块加载
local schemastore_ok, schemastore = pcall(require, "schemastore")

return {
    {
        "neovim/nvim-lspconfig",
        -- 在 VeryLazy 事件时加载
        event = { "BufReadPre", "BufNewFile" },
        -- 依赖项
        dependencies = {
            "mason.nvim",
            "mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp", -- LSP 补全源
            "b0o/schemastore.nvim", -- JSON/YAML schema 存储
        },
        -- 插件配置选项
        opts = {
            -- 诊断配置
            diagnostics = {
                underline = true,
                update_in_insert = false,
                virtual_text = {
                    spacing = 4,
                    source = "if_many",
                    prefix = "●",
                },
                severity_sort = true,
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = " ",
                        [vim.diagnostic.severity.WARN] = " ",
                        [vim.diagnostic.severity.HINT] = " ",
                        [vim.diagnostic.severity.INFO] = " ",
                    },
                },
            },
            -- 内联提示配置
            inlay_hints = {
                enabled = true,
            },
            -- 代码镜头配置
            codelens = {
                enabled = false,
            },
            -- 文档高亮配置
            document_highlight = {
                enabled = true,
            },
            -- 服务器配置
            servers = {
                -- Lua 语言服务器
                lua_ls = {
                    settings = {
                        Lua = {
                            workspace = {
                                checkThirdParty = false,
                            },
                            codeLens = {
                                enable = true,
                            },
                            completion = {
                                callSnippet = "Replace",
                            },
                        },
                    },
                },
                -- Python 语言服务器
                pyright = {
                    settings = {
                        python = {
                            analysis = {
                                typeCheckingMode = "basic",
                                autoSearchPaths = true,
                                useLibraryCodeForTypes = true,
                            },
                        },
                    },
                },
                -- Rust 语言服务器
                rust_analyzer = {
                    settings = {
                        ["rust-analyzer"] = {
                            cargo = {
                                allFeatures = true,
                                loadOutDirsFromCheck = true,
                                runBuildScripts = true,
                            },
                            checkOnSave = {
                                allFeatures = true,
                                command = "clippy",
                                extraArgs = { "--no-deps" },
                            },
                            procMacro = {
                                enable = true,
                                ignored = {
                                    ["async-trait"] = { "async_trait" },
                                    ["napi-derive"] = { "napi" },
                                    ["async-recursion"] = { "async_recursion" },
                                },
                            },
                        },
                    },
                },
                -- C/C++ 语言服务器
                clangd = {
                    cmd = {
                        "clangd",
                        "--background-index",
                        "--clang-tidy",
                        "--header-insertion=iwyu",
                        "--completion-style=detailed",
                        "--function-arg-placeholders",
                        "--fallback-style=llvm",
                    },
                    init_options = {
                        usePlaceholders = true,
                        completeUnimported = true,
                        clangdFileStatus = true,
                    },
                },
                -- Bash 语言服务器
                bashls = {},
                -- JSON 语言服务器
                jsonls = {
                    settings = {
                        json = {
                            schemas = schemastore_ok and schemastore.json.schemas({
                                select = {
                                    'package.json',
                                    '.eslintrc',
                                    'tsconfig.json',
                                    'jsconfig.json',
                                    '.babelrc',
                                    '.prettierrc',
                                    'composer.json',
                                },
                            }) or {},
                            validate = { enable = true },
                        },
                    },
                },
                -- YAML 语言服务器
                yamlls = {
                    settings = {
                        yaml = {
                            schemaStore = {
                                enable = false,
                                url = "",
                            },
                            schemas = schemastore_ok and schemastore.yaml.schemas({
                                select = {
                                    'docker-compose.yml',
                                    'GitHub Workflow',
                                    'kustomization.yaml',
                                    'ansible',
                                    '.pre-commit-config.yaml',
                                },
                            }) or {},
                            validate = true,
                            completion = true,
                            hover = true,
                        },
                    },
                },
                -- Markdown 语言服务器
                marksman = {},
            },
        },
        -- 插件配置函数
        config = function(_, opts)
            local lspconfig = require("lspconfig")
            local cmp_nvim_lsp = require("cmp_nvim_lsp")
            
            -- 设置诊断配置
            vim.diagnostic.config(vim.deepcopy(opts.diagnostics))
            
            -- 获取默认的 LSP 能力
            local capabilities = vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                cmp_nvim_lsp.default_capabilities()
            )
            
            -- 设置全局键位映射
            local function setup_keymaps()
                -- 诊断相关键位映射
                vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "行诊断" })
                vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "下一个诊断" })
                vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "上一个诊断" })
                vim.keymap.set("n", "<leader>cq", vim.diagnostic.setloclist, { desc = "诊断列表" })
            end
            
            -- 设置 LSP 附加时的键位映射
            local function on_attach(client, bufnr)
                local keymap_opts = { buffer = bufnr, silent = true }
                
                -- 启用补全
                vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
                
                -- LSP 相关键位映射
                vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", keymap_opts, { desc = "跳转到声明" }))
                vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", keymap_opts, { desc = "跳转到定义" }))
                vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", keymap_opts, { desc = "查找引用" }))
                vim.keymap.set("n", "gI", vim.lsp.buf.implementation, vim.tbl_extend("force", keymap_opts, { desc = "跳转到实现" }))
                vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, vim.tbl_extend("force", keymap_opts, { desc = "跳转到类型定义" }))
                vim.keymap.set("n", "D", vim.lsp.buf.hover, vim.tbl_extend("force", keymap_opts, { desc = "悬停文档" }))
                vim.keymap.set("n", "gK", vim.lsp.buf.signature_help, vim.tbl_extend("force", keymap_opts, { desc = "签名帮助" }))
                vim.keymap.set("i", "<c-k>", vim.lsp.buf.signature_help, vim.tbl_extend("force", keymap_opts, { desc = "签名帮助" }))
                vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, vim.tbl_extend("force", keymap_opts, { desc = "重命名" }))
                vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", keymap_opts, { desc = "代码操作" }))
                vim.keymap.set("n", "<leader>cf", function()
                    vim.lsp.buf.format({ async = true })
                end, vim.tbl_extend("force", keymap_opts, { desc = "格式化代码" }))
                
                -- 工作区相关键位映射
                vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, vim.tbl_extend("force", keymap_opts, { desc = "添加工作区文件夹" }))
                vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, vim.tbl_extend("force", keymap_opts, { desc = "移除工作区文件夹" }))
                vim.keymap.set("n", "<leader>wl", function()
                    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                end, vim.tbl_extend("force", keymap_opts, { desc = "列出工作区文件夹" }))
                
                -- 启用文档高亮
                if opts.document_highlight and opts.document_highlight.enabled and client.server_capabilities.documentHighlightProvider then
                    local group = vim.api.nvim_create_augroup("lsp_document_highlight", { clear = false })
                    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = group })
                    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                        group = group,
                        buffer = bufnr,
                        callback = vim.lsp.buf.document_highlight,
                    })
                    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                        group = group,
                        buffer = bufnr,
                        callback = vim.lsp.buf.clear_references,
                    })
                end
                
                -- 启用内联提示
                if opts.inlay_hints and opts.inlay_hints.enabled and client.server_capabilities.inlayHintProvider then
                    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                end
            end
            
            -- 设置全局键位映射
            setup_keymaps()
            
            -- 配置各个语言服务器
            for server, config in pairs(opts.servers) do
                config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, config.capabilities or {})
                config.on_attach = on_attach
                local available_server = lspconfig[server]
                if not available_server then
                    vim.notify(
                        string.format("nvim-lspconfig 未提供语言服务器 `%s`，请检查名称是否正确或更新 nvim-lspconfig", server),
                        vim.log.levels.WARN,
                        { title = "LSP" }
                    )
                else
                    available_server.setup(config)
                end
            end
        end,
    },
}