-- 现代化的 Neovim 文件浏览器
-- 支持文件系统、缓冲区、Git 状态和文档符号的树形视图

-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
    {
        -- 插件名称
        "nvim-neo-tree/neo-tree.nvim",
        -- 插件分支版本
        branch = "v3.x",
        -- 依赖项
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        -- 在命令时懒加载
        cmd = "Neotree",
        -- 按键映射时懒加载
        keys = {
            {
                "<leader>fe",
                function()
                    require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
                end,
                desc = "文件浏览器（根目录）",
            },
            {
                "<leader>fE",
                function()
                    require("neo-tree.command").execute({ toggle = true, dir = vim.fn.expand("%:p:h") })
                end,
                desc = "文件浏览器（当前文件）",
            },
            { "<leader>e", "<leader>fe", desc = "文件浏览器（根目录）", remap = true },
            { "<leader>E", "<leader>fE", desc = "文件浏览器（当前文件）", remap = true },
            {
                "<leader>be",
                function()
                    require("neo-tree.command").execute({ source = "buffers", toggle = true })
                end,
                desc = "缓冲区浏览器",
            },
            {
                "<leader>ge",
                function()
                    require("neo-tree.command").execute({ source = "git_status", toggle = true })
                end,
                desc = "Git 浏览器",
            },
        },
        -- 插件停用时执行
        deactivate = function()
            vim.cmd([[Neotree close]])
        end,
        -- 插件初始化时执行
        init = function()
            -- 如果启动时只有一个参数且是目录，则自动打开 neo-tree
            if vim.fn.argc(-1) == 1 then
                local stat = vim.uv.fs_stat(vim.fn.argv(0))
                if stat and stat.type == "directory" then
                    require("neo-tree")
                end
            end
        end,
        -- 插件配置选项
        opts = {
            -- 数据源
            sources = { "filesystem", "buffers", "git_status", "document_symbols" },
            -- 不替换的文件类型
            open_files_do_not_replace_types = { "terminal", "trouble", "qf", "Outline" },
            -- 文件系统配置
            filesystem = {
                -- 绑定到当前工作目录
                bind_to_cwd = false,
                -- 跟随当前文件
                follow_current_file = {
                    enabled = true,
                    leave_dirs_open = false,
                },
                -- 使用 libuv 文件监视器
                use_libuv_file_watcher = true,
                -- 过滤器
                filtered_items = {
                    visible = false,
                    hide_dotfiles = true,
                    hide_gitignored = true,
                    hide_hidden = true,
                    hide_by_name = {
                        "node_modules",
                        ".git",
                        ".DS_Store",
                        "thumbs.db",
                    },
                    hide_by_pattern = {
                        "*.tmp",
                        "*.pyc",
                    },
                    always_show = {
                        ".gitignored",
                    },
                    never_show = {
                        ".DS_Store",
                        "thumbs.db",
                    },
                },
                -- 查找命令
                find_command = "fd",
                find_args = {
                    fd = {
                        "--exclude", ".git",
                        "--exclude", "node_modules",
                    },
                },
                -- 组空文件夹
                group_empty_dirs = false,
                -- 搜索限制
                search_limit = 50,
                -- 停止搜索的文件夹
                stop_at_git_root = true,
            },
            -- 缓冲区配置
            buffers = {
                follow_current_file = {
                    enabled = true,
                    leave_dirs_open = false,
                },
                group_empty_dirs = true,
                show_unloaded = true,
            },
            -- Git 状态配置
            git_status = {
                window = {
                    position = "float",
                    mappings = {
                        ["A"] = "git_add_all",
                        ["gu"] = "git_unstage_file",
                        ["ga"] = "git_add_file",
                        ["gr"] = "git_revert_file",
                        ["gc"] = "git_commit",
                        ["gp"] = "git_push",
                        ["gg"] = "git_commit_and_push",
                    },
                },
            },
            -- 窗口配置
            window = {
                position = "left",
                width = 40,
                mapping_options = {
                    noremap = true,
                    nowait = true,
                },
                mappings = {
                    ["<space>"] = {
                        "toggle_node",
                        nowait = false,
                    },
                    ["<2-LeftMouse>"] = "open",
                    ["<cr>"] = "open",
                    ["<esc>"] = "cancel",
                    ["P"] = { "toggle_preview", config = { use_float = true, use_image_nvim = true } },
                    ["l"] = "focus_preview",
                    ["S"] = "open_split",
                    ["s"] = "open_vsplit",
                    ["t"] = "open_tabnew",
                    ["w"] = "open_with_window_picker",
                    ["C"] = "close_node",
                    ["z"] = "close_all_nodes",
                    ["Z"] = "expand_all_nodes",
                    ["a"] = {
                        "add",
                        config = {
                            show_path = "none",
                        },
                    },
                    ["A"] = "add_directory",
                    ["d"] = "delete",
                    ["r"] = "rename",
                    ["y"] = "copy_to_clipboard",
                    ["x"] = "cut_to_clipboard",
                    ["p"] = "paste_from_clipboard",
                    ["c"] = "copy",
                    ["m"] = "move",
                    ["q"] = "close_window",
                    ["R"] = "refresh",
                    ["?"] = "show_help",
                    ["<"] = "prev_source",
                    [">"] = "next_source",
                    ["i"] = "noop",  -- 禁用 i 键
                    ["gd"] = "show_file_details",  -- 使用 gd 显示文件详情
                },
            },
            -- 嵌套文件配置
            nesting_rules = {},
            -- 默认组件配置
            default_component_configs = {
                container = {
                    enable_character_fade = true,
                },
                indent = {
                    indent_size = 2,
                    padding = 1,
                    with_markers = true,
                    indent_marker = "│",
                    last_indent_marker = "└",
                    highlight = "NeoTreeIndentMarker",
                    with_expanders = nil,
                    expander_collapsed = "",
                    expander_expanded = "",
                    expander_highlight = "NeoTreeExpander",
                },
                icon = {
                    folder_closed = "",
                    folder_open = "",
                    folder_empty = "󰜌",
                    default = "*",
                    highlight = "NeoTreeFileIcon",
                },
                modified = {
                    symbol = "[+]",
                    highlight = "NeoTreeModified",
                },
                name = {
                    trailing_slash = false,
                    use_git_status_colors = true,
                    highlight = "NeoTreeFileName",
                },
                git_status = {
                    symbols = {
                        added = "",
                        modified = "",
                        deleted = "✖",
                        renamed = "󰁕",
                        untracked = "",
                        ignored = "",
                        unstaged = "󰄱",
                        staged = "",
                        conflict = "",
                    },
                },
                file_size = {
                    enabled = true,
                    required_width = 64,
                },
                type = {
                    enabled = true,
                    required_width = 122,
                },
                last_modified = {
                    enabled = true,
                    required_width = 88,
                },
                created = {
                    enabled = true,
                    required_width = 110,
                },
                symlink_target = {
                    enabled = false,
                },
            },
            -- 命令配置
            commands = {},
            -- 窗口选择器配置
            window_picker = {
                enable = true,
                picker = "window-picker",
                window_picker_config = {
                    filter_rules = {
                        include_current_win = false,
                        autoselect_one = true,
                        bo = {
                            filetype = { "neo-tree", "neo-tree-popup", "notify" },
                            buftype = { "terminal", "quickfix" },
                        },
                    },
                },
            },
            -- 文件系统监视器配置
            filesystem_watchers = {
                enable = true,
            },
            -- Git 配置
            git = {
                enable = true,
                show_untracked = true,
                show_ignored = false,
            },
            -- 日志配置
            log = {
                enable = false,
                level = "info",
                use_console = false,
            },
        },
        -- 插件配置函数
        config = function(_, opts)
            -- 文件移动/重命名时的 LSP 处理
            local function on_move(data)
                -- 如果有 LazyVim 工具，使用其 LSP 重命名功能
                if pcall(require, "lazyvim.util") then
                    require("lazyvim.util").lsp.on_rename(data.source, data.destination)
                end
            end

            local events = require("neo-tree.events")
            opts.event_handlers = opts.event_handlers or {}
            vim.list_extend(opts.event_handlers, {
                { event = events.FILE_MOVED, handler = on_move },
                { event = events.FILE_RENAMED, handler = on_move },
            })

            require("neo-tree").setup(opts)

            -- 自动刷新 Git 状态
            vim.api.nvim_create_autocmd("TermClose", {
                pattern = "*lazygit",
                callback = function()
                    if package.loaded["neo-tree.sources.git_status"] then
                        require("neo-tree.sources.git_status").refresh()
                    end
                end,
            })
        end,
    },
}