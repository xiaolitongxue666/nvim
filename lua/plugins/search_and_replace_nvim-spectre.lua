-- 强大的搜索和替换工具
-- 支持正则表达式、多文件搜索替换、实时预览等功能

-- https://github.com/nvim-pack/nvim-spectre

return {
    {
        "nvim-pack/nvim-spectre",
        -- 在命令和按键映射时懒加载
        cmd = "Spectre",
        keys = {
            { "<leader>sr", function() require("spectre").toggle() end, desc = "替换" },
            { "<leader>sw", function() require("spectre").open_visual({select_word=true}) end, desc = "搜索当前单词" },
            { "<leader>sw", function() require("spectre").open_visual() end, mode = "v", desc = "搜索当前选择" },
            { "<leader>sp", function() require("spectre").open_file_search({select_word=true}) end, desc = "在当前文件中搜索" },
        },
        -- 插件配置选项
        opts = {
            -- 颜色主题
            color_devicons = true,
            -- 打开命令
            open_cmd = "noswapfile vnew",
            -- 实时更新
            live_update = false,
            -- 行号
            line_sep_start = "┌─────────────────────────────────────────",
            result_padding = "│  ",
            line_sep       = "└─────────────────────────────────────────",
            -- 高亮设置
            highlight = {
                ui = "String",
                search = "DiffChange",
                replace = "DiffDelete"
            },
            -- 映射配置
            mapping = {
                ['toggle_line'] = {
                    map = "dd",
                    cmd = "<cmd>lua require('spectre').toggle_line()<CR>",
                    desc = "切换当前行"
                },
                ['enter_file'] = {
                    map = "<cr>",
                    cmd = "<cmd>lua require('spectre').open_file_search({select_word=true})<CR>",
                    desc = "跳转到文件"
                },
                ['send_to_qf'] = {
                    map = "<leader>q",
                    cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
                    desc = "发送所有项目到 quickfix"
                },
                ['replace_cmd'] = {
                    map = "<leader>c",
                    cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
                    desc = "输入替换命令"
                },
                ['show_option_menu'] = {
                    map = "<leader>o",
                    cmd = "<cmd>lua require('spectre').show_options()<CR>",
                    desc = "显示选项"
                },
                ['run_current_replace'] = {
                    map = "<leader>rc",
                    cmd = "<cmd>lua require('spectre.actions').run_current_replace()<CR>",
                    desc = "替换当前行"
                },
                ['run_replace'] = {
                    map = "<leader>R",
                    cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
                    desc = "替换所有"
                },
                ['change_view_mode'] = {
                    map = "<leader>v",
                    cmd = "<cmd>lua require('spectre').change_view()<CR>",
                    desc = "改变结果视图模式"
                },
                ['change_replace_sed'] = {
                    map = "trs",
                    cmd = "<cmd>lua require('spectre').change_engine_replace('sed')<CR>",
                    desc = "使用 sed 替换"
                },
                ['change_replace_oxi'] = {
                    map = "tro",
                    cmd = "<cmd>lua require('spectre').change_engine_replace('oxi')<CR>",
                    desc = "使用 oxi 替换"
                },
                ['toggle_live_update'] = {
                    map = "tu",
                    cmd = "<cmd>lua require('spectre').toggle_live_update()<CR>",
                    desc = "切换实时更新"
                },
                ['toggle_ignore_case'] = {
                    map = "ti",
                    cmd = "<cmd>lua require('spectre').change_options('ignore-case')<CR>",
                    desc = "切换忽略大小写"
                },
                ['toggle_ignore_hidden'] = {
                    map = "th",
                    cmd = "<cmd>lua require('spectre').change_options('hidden')<CR>",
                    desc = "切换搜索隐藏文件"
                },
                ['resume_last_search'] = {
                    map = "<leader>l",
                    cmd = "<cmd>lua require('spectre').resume_last_search()<CR>",
                    desc = "恢复上次搜索"
                },
            },
            -- 查找引擎配置
            find_engine = {
                -- rg 是默认的
                ['rg'] = {
                    cmd = "rg",
                    args = {
                        '--color=never',
                        '--no-heading',
                        '--with-filename',
                        '--line-number',
                        '--column',
                    },
                    options = {
                        ['ignore-case'] = {
                            value = "--ignore-case",
                            icon = "[I]",
                            desc = "忽略大小写"
                        },
                        ['hidden'] = {
                            value = "--hidden",
                            desc = "隐藏文件",
                            icon = "[H]"
                        },
                    }
                },
            },
            -- 替换引擎配置
            replace_engine = {
                ['sed'] = {
                    cmd = "sed",
                    args = nil,
                    options = {
                        ['ignore-case'] = {
                            value = "--ignore-case",
                            icon = "[I]",
                            desc = "忽略大小写"
                        },
                    }
                },
            },
            -- 默认替换模板
            default = {
                find = {
                    cmd = "rg",
                    options = {"ignore-case"}
                },
                replace = {
                    cmd = "sed"
                }
            },
        },
    },
}