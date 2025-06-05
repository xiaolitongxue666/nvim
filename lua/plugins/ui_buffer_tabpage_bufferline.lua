-- akinsho/bufferline.nvim

-- A snazzy bufferline for Neovim

-- https://github.com/akinsho/bufferline.nvim

return {
    {
        -- Plu name
        "akinsho/bufferline.nvim",
        -- This is mainly useful for Neovim distros, to allow setting options on plugins that may/may not be part of the user's plugins
        optional = true,
        -- Lazy-load on key mapping
        keys = {
            { "<C-j>", ":BufferLineCyclePrev<CR>", desc = "Previous buffer" },
            { "<C-l>", ":BufferLineCycleNext<CR>", desc = "Next buffer" },
        },
        -- Opts is a table will be passed to the Plugin.config() function. Setting this value will imply Plugin.config()
        opts = function()
            local Offset = require("bufferline.offset")
            if not Offset.edgy then
                local get = Offset.get
                Offset.get = function()
                    if package.loaded.edgy then
                        local layout = require("edgy.config").layout
                        local ret = { left = "", left_size = 0, right = "", right_size = 0 }
                        for _, pos in ipairs({ "left", "right" }) do
                            local sb = layout[pos]
                            if sb and #sb.wins > 0 then
                                local title = " Sidebar" .. string.rep(" ", sb.bounds.width - 8)
                                ret[pos] = "%#EdgyTitle#" .. title .. "%*" .. "%#WinSeparator#│%*"
                                ret[pos .. "_size"] = sb.bounds.width
                            end
                        end
                        ret.total_size = ret.left_size + ret.right_size
                        if ret.total_size > 0 then
                            return ret
                        end
                    end
                    return get()
                end
                Offset.edgy = true
            end
        end,
    },
}