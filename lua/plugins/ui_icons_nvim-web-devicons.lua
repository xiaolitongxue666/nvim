-- Neovim 文件图标插件
-- 为文件类型提供美观的图标显示

-- https://github.com/nvim-tree/nvim-web-devicons

return {
    {
        -- 插件名称
        "nvim-tree/nvim-web-devicons",
        -- 当为 true 时，插件只在需要时加载
        lazy = true,
        -- 插件配置选项
        opts = {
            -- 全局启用（默认为 true）
            default = true,
            -- 严格模式（只显示已定义的图标）
            strict = true,
            -- 覆盖默认图标
            override = {
                zsh = {
                    icon = "",
                    color = "#428850",
                    cterm_color = "65",
                    name = "Zsh"
                },
                ["init.lua"] = {
                    icon = "",
                    color = "#51a0cf",
                    cterm_color = "74",
                    name = "InitLua"
                },
                ["README.md"] = {
                    icon = "",
                    color = "#519aba",
                    cterm_color = "74",
                    name = "Readme"
                },
                [".gitignore"] = {
                    icon = "",
                    color = "#f1502f",
                    cterm_color = "196",
                    name = "GitIgnore"
                },
                [".env"] = {
                    icon = "",
                    color = "#faf743",
                    cterm_color = "227",
                    name = "Env"
                },
                ["docker-compose.yml"] = {
                    icon = "",
                    color = "#458ee6",
                    cterm_color = "68",
                    name = "DockerCompose"
                },
                ["Dockerfile"] = {
                    icon = "",
                    color = "#458ee6",
                    cterm_color = "68",
                    name = "Dockerfile"
                },
            },
            -- 按文件扩展名覆盖
            override_by_extension = {
                ["log"] = {
                    icon = "",
                    color = "#81e043",
                    cterm_color = "113",
                    name = "Log"
                },
                ["conf"] = {
                    icon = "",
                    color = "#6d8086",
                    cterm_color = "66",
                    name = "Conf"
                },
                ["config"] = {
                    icon = "",
                    color = "#6d8086",
                    cterm_color = "66",
                    name = "Config"
                },
            },
            -- 按文件名覆盖
            override_by_filename = {
                ["makefile"] = {
                    icon = "",
                    color = "#f1502f",
                    cterm_color = "196",
                    name = "Makefile"
                },
                ["Makefile"] = {
                    icon = "",
                    color = "#f1502f",
                    cterm_color = "196",
                    name = "Makefile"
                },
                ["MAKEFILE"] = {
                    icon = "",
                    color = "#f1502f",
                    cterm_color = "196",
                    name = "Makefile"
                },
            },
            -- 按操作系统覆盖
            override_by_operating_system = {
                ["apple"] = {
                    icon = "",
                    color = "#A2AAAD",
                    cterm_color = "248",
                    name = "Apple"
                },
            },
            -- 颜色图标（需要终端支持真彩色）
            color_icons = true,
        },
        -- 插件配置函数
        config = function(_, opts)
            require("nvim-web-devicons").setup(opts)
        end,
    },
}