-- neo-tree.nvim
-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim
return {
    {
        -- lazy.nvim property : : plug name
        "nvim-neo-tree/neo-tree.nvim",
        -- lazy.nvim property : branch : branch of plug repository
        branch = "v3.x",
        -- lazy.nvim property : cmd : lazy-load on command
        cmd = "Neotree",
        -- -- lazy.nvim property : keys : lazy-load on key mapping
        keys = {
            --{
            --    "<leader>fe",
            --    function()
            --        require("neo-tree.command").execute({ toggle = true, dir = require("lazyvim.util").get_root() })
            --    end,
            --    desc = "Explorer NeoTree (root dir)",
            --},
            {
                "<leader>fe",
                function()
                    require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
                end,
                desc = "Explorer NeoTree (cwd)",
            },
            { "<leader>e", "<leader>fe", desc = "Explorer NeoTree (root dir)", remap = true },
            { "<leader>E", "<leader>fE", desc = "Explorer NeoTree (cwd)", remap = true },
        },
        deactivate = function()
            vim.cmd([[Neotree close]])
        end,
        -- lazy.nvim property : init : functions are always executed during startup
        init = function()
            -- neovim builtin function : argc([{winid}])
            -- If {winid} is not supplied, the argument list of the current window is used.
            if vim.fn.argc() == 1 then
                -- neovim builtin function : argv([{winid}])
                -- The result is the {nr}th file in the argument list.
                local stat = vim.loop.fs_stat(vim.fn.argv(0))
                if stat and stat.type == "directory" then
                    require("neo-tree")
                end
            end
        end,
        opts = {
            sources = { "filesystem", "buffers", "git_status", "document_symbols" },
            open_files_do_not_replace_types = { "terminal", "Trouble", "qf", "Outline" },
            filesystem = {
                bind_to_cwd = false,
                follow_current_file = { enabled = true }, -- intelligently follow the current file
                use_libuv_file_watcher = true,  -- auto refresh
            },
            window = {
                mappings = {
                    ["<space>"] = "none",
                },
            },
            default_component_configs = {
                indent = {
                    with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
                    expander_collapsed = "",
                    expander_expanded = "",
                    expander_highlight = "NeoTreeExpander",
                },
            },
        },
        config = function(_, opts)
            require("neo-tree").setup(opts)
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