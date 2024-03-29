-- jbyuki/one-small-step-for-vimkind

-- Debug adapter for Neovim plugins

-- https://github.com/jbyuki/one-small-step-for-vimkind

return {
    -- Plug name
    "jbyuki/one-small-step-for-vimkind",
    -- Config is executed when the plugin loads.
    config = function()
        local dap = require("dap")
        dap.adapters.nlua = function(callback, config)
            callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
        end
        dap.configurations.lua = {
            {
                type = "nlua",
                request = "attach",
                name = "Attach to running Neovim instance",
            },
        }
    end,
    -- Lazy-load on key mapping
    keys = {
        { "<leader>daL", function() require("osv").launch({ port = 8086 }) end, desc = "Adapter Lua Server" },
        { "<leader>dal", function() require("osv").run_this() end, desc = "Adapter Lua" },
    },
}

