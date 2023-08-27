-- williamboman/mason.nvim

-- Portable package manager for Neovim
-- that runs everywhere Neovim runs.
-- Easily install and manage LSP servers, DAP servers, linters, and formatters

-- https://github.com/williamboman/mason.nvim

return {
    {
        -- Plug name
        "williamboman/mason.nvim",
        -- Lazy-load on command
        cmd = "Mason",
        -- Lazy-load on key mapping
        keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
        -- Build is executed when a plugin is installed or updated
        build = ":MasonUpdate", -- :MasonUpdate updates registry contents
        -- Opts is a table will be passed to the Plugin.config() function. Setting this value will imply Plugin.config()
        opts = {
            ensure_installed = {
            -- For a list of all available packages, see https://mason-registry.dev/registry/list.
                "stylua", -- lua
                "shfmt",  -- sh/bash/mksh
                "clangd", -- c/c++
                "lua_ls", -- lua
                "pyright", -- python
                "rust-analyzer", -- rust
            },
        },
        -- Config is executed when the plugin loads.
        config = function(_, opts)
            require("mason").setup(opts)
            local mr = require("mason-registry")
            local function ensure_installed()
                for _, tool in ipairs(opts.ensure_installed) do
                    local p = mr.get_package(tool)
                    if not p:is_installed() then
                        p:install()
                    end
                end
            end
            if mr.refresh then
                mr.refresh(ensure_installed)
            else
                ensure_installed()
            end

        end,
    },
}