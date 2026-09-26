-- stevearc/overseer.nvim
-- 任务运行与管理，统一管理构建、脚本与命令的输出查看
-- https://github.com/stevearc/overseer.nvim

return {
    {
        "stevearc/overseer.nvim",
        cmd = {
            "OverseerOpen",
            "OverseerClose",
            "OverseerToggle",
            "OverseerRun",
            "OverseerRunCmd",
            "OverseerQuickAction",
            "OverseerTaskAction",
            "OverseerLoadBundle",
            "OverseerInfo",
            "OverseerRunCurrent",
        },
        keys = {
            { "<leader>or", "<cmd>OverseerRun<cr>", desc = "选择并运行任务" },
            { "<leader>oo", "<cmd>OverseerToggle<cr>", desc = "切换任务列表" },
            { "<leader>oa", "<cmd>OverseerQuickAction<cr>", desc = "任务快速操作" },
            { "<leader>of", "<cmd>OverseerRunCurrent<cr>", desc = "运行当前文件模板" },
        },
        config = function()
            local overseer = require("overseer")
            local function shell_wrap(script)
                if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
                    return { "cmd.exe", "/C", script }
                else
                    return { "bash", "-lc", script }
                end
            end

            local function python_executable()
                if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
                    return "python"
                end
                return "python3"
            end

            local function temp_executable_name()
                local name = vim.fn.tempname()
                if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
                    return name .. ".exe"
                end
                return name
            end

            local command_map = {
                lua = function(path)
                    return { "lua", path }
                end,
                python = function(path)
                    return { python_executable(), path }
                end,
                javascript = function(path)
                    return { "node", path }
                end,
                typescript = function(path)
                    return { "ts-node", path }
                end,
                sh = function(path)
                    return { "bash", path }
                end,
                c = function(path)
                    local output = temp_executable_name()
                    local compile = string.format("gcc %s -o %s && %s", vim.fn.shellescape(path), vim.fn.shellescape(output), vim.fn.shellescape(output))
                    return shell_wrap(compile)
                end,
                cpp = function(path)
                    local output = temp_executable_name()
                    local compile = string.format("g++ %s -o %s && %s", vim.fn.shellescape(path), vim.fn.shellescape(output), vim.fn.shellescape(output))
                    return shell_wrap(compile)
                end,
                rust = function(path)
                    local output = temp_executable_name()
                    local compile = string.format("rustc %s -o %s && %s", vim.fn.shellescape(path), vim.fn.shellescape(output), vim.fn.shellescape(output))
                    return shell_wrap(compile)
                end,
            }
            local supported_filetypes = vim.tbl_keys(command_map)

            overseer.setup({
                -- 默认使用 toggleterm 作为任务终端，方便与现有终端工作流保持一致
                strategy = {
                    "toggleterm",
                    direction = "horizontal",
                    size = 20,
                    open_on_start = true,
                    close_on_exit = false,
                    auto_scroll = true,
                    hidden = false,
                },
                -- 内置模板在「当前目录没有对应工程文件」时会让 :checkhealth 报 WARNING。
                -- cargo / make / npm 关掉原模块，下面再用静默包装重新注册：没有工程文件时不报警，有文件时任务仍在。
                disable_template_modules = {
                    "overseer.template.cargo",
                    "overseer.template.cargo-make",
                    "overseer.template.composer",
                    "overseer.template.deno",
                    "overseer.template.devenv",
                    "overseer.template.just",
                    "overseer.template.make",
                    "overseer.template.mage",
                    "overseer.template.mise",
                    "overseer.template.mix",
                    "overseer.template.npm",
                    "overseer.template.rake",
                    "overseer.template.task",
                    "overseer.template.tox",
                    "overseer.template.vscode",
                },
                -- 任务列表窗口设置（底部滑出，保持简洁）
                task_list = {
                    direction = "bottom",
                    min_height = 12,
                    max_height = 24,
                    default_detail = 1,
                },
            })

            local function register_quiet_provider(provider_name, module_name, quiet_messages)
                local template = require(module_name)
                local original_generator = template.generator
                local quiet = {}
                for _, message in ipairs(quiet_messages) do
                    quiet[message] = true
                end
                overseer.register_template({
                    name = provider_name,
                    cache_key = template.cache_key,
                    generator = function(opts, callback)
                        local delivered = false
                        local function deliver(result)
                            if delivered then
                                return
                            end
                            delivered = true
                            if type(result) == "string" and quiet[result] then
                                callback({})
                            else
                                callback(result)
                            end
                        end
                        local sync_result = original_generator(opts, deliver)
                        if sync_result ~= nil then
                            deliver(sync_result)
                        end
                    end,
                })
            end

            register_quiet_provider("cargo", "overseer.template.cargo", { "No Cargo.toml file found" })
            register_quiet_provider("make", "overseer.template.make", { "No Makefile found" })
            register_quiet_provider("npm", "overseer.template.npm", { "No package.json file found" })

            -- 自定义模板：根据文件类型运行当前缓冲区。
            -- 条件放在任务上，不放在 provider 上。provider 条件失败会被 checkhealth 记成 WARNING。
            overseer.register_template({
                name = "Run current file",
                generator = function()
                    return {
                        {
                            name = "Run current file",
                            desc = "使用匹配的解释器/运行时执行当前缓冲区文件",
                            condition = {
                                filetype = supported_filetypes,
                            },
                            builder = function()
                    local buffer_path = vim.api.nvim_buf_get_name(0)
                    if buffer_path == "" then
                        vim.notify("当前缓冲区没有文件路径，请先保存文件再运行", vim.log.levels.WARN, {
                            title = "Overseer",
                        })
                        return {
                            cmd = { "echo", "当前缓冲区没有文件路径，请先保存文件再运行" },
                            components = { "default" },
                            cwd = vim.fn.getcwd(),
                        }
                    end

                    local filetype = vim.bo.filetype
                    local build_command = command_map[filetype]
                    if not build_command then
                        return {
                            cmd = { "echo", string.format("未为 %s 文件配置运行方式", filetype) },
                            components = { "default" },
                            cwd = vim.fn.getcwd(),
                        }
                    end

                    local command = build_command(buffer_path)

                    return {
                        cmd = command,
                        components = { "default" },
                        cwd = vim.fn.getcwd(),
                    }
                            end,
                        },
                    }
                end,
            })

            vim.api.nvim_create_user_command("OverseerRunCurrent", function()
                local ok, _ = pcall(overseer.run_template, { name = "Run current file" })
                if not ok then
                    vim.notify("当前文件类型未定义 Overseer 模板", vim.log.levels.WARN, {
                        title = "Overseer",
                    })
                end
            end, { desc = "运行当前文件 Overseer 模板" })
        end,
    },
}

