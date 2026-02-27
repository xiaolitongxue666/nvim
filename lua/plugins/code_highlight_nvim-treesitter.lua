-- nvim-treesitter/nvim-treesitter
--
-- Nvim Treesitter 配置和抽象层
-- 提供语法高亮、缩进、增量选择等功能
--
-- 官方文档: https://github.com/nvim-treesitter/nvim-treesitter
-- 要求: Neovim 0.11.0+, tar, curl, tree-sitter-cli (0.26.1+), C 编译器
--
-- 注意: 此插件不支持懒加载，必须在启动时加载

return {
    {
        -- 插件名称
        "nvim-treesitter/nvim-treesitter",
        -- 指定 master 分支（官方要求）
        branch = 'master',
        -- 禁用懒加载，官方不支持懒加载
        lazy = false,
        -- Windows 环境：禁用自动构建（使用手动编译的解析器）
        -- 在 UNIX 系统上可以启用: build = ":TSUpdate",
        build = false,
        -- Opts 是一个将传递给 Plugin.config() 函数的表。设置此值将隐含 Plugin.config()
        opts = {
            -- 语法高亮（由 Neovim 内置提供）
            highlight = {
                enable = true,
                -- 使用额外的正则表达式高亮（如果 treesitter 不支持）
                additional_vim_regex_highlighting = false,
            },
            
            -- 基于 treesitter 的缩进（实验性功能）
            indent = {
                enable = true,
                -- 禁用某些语言的缩进（如果出现问题）
                disable = {},
            },
            
            -- 禁用自动安装（Windows 上有路径兼容问题）
            auto_install = false,
            
            -- 忽略解析器安装错误，避免启动时崩溃
            ignore_install = {},
            
            -- Windows 环境：禁用 ensure_installed 避免触发自动编译
            -- 解析器已手动编译并放置在 %LOCALAPPDATA%/nvim-data/site/parser/
            -- 如需添加新解析器，使用脚本手动编译或参考 README
            ensure_installed = {},
            
            -- 增量选择功能
            -- 允许逐步扩展或缩小文本选择范围
            incremental_selection = {
                enable = true,
                keymaps = {
                    -- 初始化选择（开始增量选择）
                    init_selection = "<C-space>",
                    -- 扩展选择到下一个节点
                    node_incremental = "<C-space>",
                    -- 扩展选择到下一个作用域（已禁用）
                    scope_incremental = false,
                    -- 缩小选择范围
                    node_decremental = "<bs>",
                },
            },
        },
        -- 插件加载时执行的配置函数
        config = function(_, opts)
            -- 多 OS 兼容：仅非 Windows 自动安装 noice 等所需的解析器（Windows 存在路径/编译问题）
            if vim.fn.has("win32") ~= 1 and vim.fn.has("win64") ~= 1 then
                opts.ensure_installed = { "vim", "regex", "lua", "bash", "markdown", "markdown_inline" }
            end
            -- 去重 ensure_installed 列表，避免重复安装
            if type(opts.ensure_installed) == "table" then
                ---@type table<string, boolean>
                local added = {}
                opts.ensure_installed = vim.tbl_filter(function(lang)
                    if added[lang] then
                        return false
                    end
                    added[lang] = true
                    return true
                end, opts.ensure_installed)
            end
            
            -- 设置 treesitter 配置，使用 pcall 捕获错误
            local ok, treesitter = pcall(require, "nvim-treesitter.configs")
            if ok then
                treesitter.setup(opts)
                
                -- Windows 环境下添加诊断命令
                if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
                    -- 诊断命令：检查编译环境和工具
                    vim.api.nvim_create_user_command("TSCheckCompiler", function()
                        local results = {}
                        table.insert(results, "=== nvim-treesitter 编译器诊断 ===\n")
                        
                        -- 检查编译器
                        local compilers = { "gcc", "cl", "clang", "zig", "cc" }
                        local found_compiler = false
                        
                        for _, compiler in ipairs(compilers) do
                            if vim.fn.executable(compiler) == 1 then
                                found_compiler = true
                                local version_output = vim.fn.system(compiler .. (compiler == "cl" and " 2>&1" or " --version 2>&1"))
                                local first_line = vim.split(version_output, "\n")[1] or "可用"
                                table.insert(results, "✓ " .. compiler .. ": " .. first_line)
                                
                                -- 测试编译一个简单程序
                                if compiler == "gcc" or compiler == "clang" then
                                    local test_file = vim.fn.tempname() .. ".c"
                                    local test_exe = vim.fn.tempname() .. ".exe"
                                    local test_code = "int main(){return 0;}"
                                    vim.fn.writefile({ test_code }, test_file)
                                    local compile_cmd = string.format('%s -o "%s" "%s" 2>&1', compiler, test_exe, test_file)
                                    local compile_result = vim.fn.system(compile_cmd)
                                    if vim.v.shell_error == 0 then
                                        table.insert(results, "  → 编译测试: 成功")
                                        vim.fn.delete(test_file)
                                        vim.fn.delete(test_exe)
                                    else
                                        table.insert(results, "  → 编译测试: 失败 - " .. (vim.split(compile_result, "\n")[1] or "未知错误"))
                                    end
                                end
                            end
                        end
                        
                        if not found_compiler then
                            table.insert(results, "✗ 未找到任何 C 编译器")
                            table.insert(results, "")
                            table.insert(results, "建议:")
                            table.insert(results, "1. 安装 MinGW-w64: https://www.mingw-w64.org/")
                            table.insert(results, "2. 或安装 Visual Studio Build Tools")
                            table.insert(results, "3. 或从 Visual Studio Developer Command Prompt 启动 Neovim")
                        end
                        
                        -- 检查其他工具
                        table.insert(results, "")
                        table.insert(results, "=== 其他工具 ===")
                        local tools = {
                            { name = "tar", cmd = "tar --version" },
                            { name = "curl", cmd = "curl --version" },
                            { name = "tree-sitter", cmd = "tree-sitter --version" },
                        }
                        
                        for _, tool in ipairs(tools) do
                            if vim.fn.executable(tool.name) == 1 then
                                local output = vim.fn.system(tool.cmd .. " 2>&1")
                                local first_line = vim.split(output, "\n")[1] or "可用"
                                table.insert(results, "✓ " .. tool.name .. ": " .. first_line)
                            else
                                table.insert(results, "✗ " .. tool.name .. ": 未找到")
                            end
                        end
                        
                        -- 显示 PATH
                        table.insert(results, "")
                        table.insert(results, "=== PATH 环境变量 (前10项) ===")
                        local path_parts = vim.split(vim.env.PATH or "", ";")
                        for i = 1, math.min(10, #path_parts) do
                            if path_parts[i] and path_parts[i] ~= "" then
                                table.insert(results, path_parts[i])
                            end
                        end
                        
                        -- 显示解析器安装目录
                        table.insert(results, "")
                        table.insert(results, "=== 解析器安装目录 ===")
                        local install_dir = vim.fn.stdpath('data') .. '/site'
                        table.insert(results, install_dir)
                        if vim.fn.isdirectory(install_dir) == 1 then
                            local parser_dir = install_dir .. "/parser"
                            if vim.fn.isdirectory(parser_dir) == 1 then
                                local parsers = vim.fn.readdir(parser_dir)
                                table.insert(results, "已安装解析器数量: " .. (#parsers or 0))
                            else
                                table.insert(results, "解析器目录不存在")
                            end
                        else
                            table.insert(results, "安装目录不存在")
                        end
                        
                        -- 输出结果
                        local msg = table.concat(results, "\n")
                        vim.notify(msg, vim.log.levels.INFO)
                        
                        -- 同时写入到文件
                        local log_file = vim.fn.stdpath('cache') .. '/treesitter_diagnostic.txt'
                        vim.fn.writefile(vim.split(msg, "\n"), log_file)
                        vim.notify("详细诊断信息已保存到: " .. log_file, vim.log.levels.INFO)
                    end, { desc = "检查 nvim-treesitter 编译环境和工具" })
                    
                    -- 命令：查看编译日志
                    vim.api.nvim_create_user_command("TSViewLogs", function()
                        local install_dir = vim.fn.stdpath('data') .. '/site'
                        local parser_dir = install_dir .. "/parser"
                        
                        if vim.fn.isdirectory(parser_dir) == 0 then
                            vim.notify("解析器目录不存在: " .. parser_dir, vim.log.levels.WARN)
                            return
                        end
                        
                        local parsers = vim.fn.readdir(parser_dir)
                        local failed_parsers = {}
                        
                        for _, parser_file in ipairs(parsers or {}) do
                            local parser_path = parser_dir .. "/" .. parser_file
                            if vim.fn.filereadable(parser_path) == 0 then
                                local lang = parser_file:match("([^/]+)%.so$") or parser_file:match("([^/]+)%.dll$")
                                if lang then
                                    table.insert(failed_parsers, lang)
                                end
                            end
                        end
                        
                        if #failed_parsers > 0 then
                            vim.notify("以下解析器编译失败或文件缺失:\n" .. table.concat(failed_parsers, ", "), vim.log.levels.WARN)
                        else
                            vim.notify("所有解析器文件都存在", vim.log.levels.INFO)
                        end
                    end, { desc = "查看解析器编译状态" })
                end
            else
                vim.notify("nvim-treesitter 配置失败: " .. tostring(treesitter), vim.log.levels.ERROR)
            end
        end,
    },
}