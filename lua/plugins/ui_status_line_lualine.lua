-- nvim-lualine/lualine.nvim

-- A blazing fast and easy to configure neovim statusline plugin written in pure lua.

-- https://github.com/nvim-lualine/lualine.nvim

return {
    {
        -- Plug name
        "nvim-lualine/lualine.nvim",
        -- Config is executed when the plugin loads.
        event = "VeryLazy",
        -- Opts is a table will be passed to the Plugin.config() function. Setting this value will imply Plugin.config()
        opts = function()
            return {
                options = {
                    icons_enabled = true,
                    theme = 'auto',
                    component_separators = { left = '', right = ''},
                    section_separators = { left = '', right = ''},
                    disabled_filetypes = {
                        statusline = {},
                        winbar = {},
                    },
                    ignore_focus = {},
                    always_divide_middle = true,
                    globalstatus = false,
                    refresh = {
                        statusline = 1000,
                        tabline = 1000,
                        winbar = 1000,
                    }
                },
                sections = {
                    lualine_a = {'mode'},
                    lualine_b = {'branch', 'diff', 'diagnostics'},
                    lualine_c = {'filename'},
                    lualine_x = {'encoding', 'fileformat', 'filetype'},
                    lualine_y = {'progress'},
                    lualine_z = {
                        'location',
                        (function()
                            local ok, opencode = pcall(require, "opencode")
                            if ok and opencode and opencode.statusline then
                                return { opencode.statusline }
                            end
                            return {}
                        end)(),
                    }
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = {'filename'},
                    lualine_x = {'location'},
                    lualine_y = {},
                    lualine_z = {}
                },
                tabline = {},
                winbar = {},
                inactive_winbar = {},
                extensions = {}
            }
        end,
    },
}