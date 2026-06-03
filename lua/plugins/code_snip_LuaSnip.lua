-- L3MON4D3/LuaSnip
-- Neovim 代码片段引擎
-- https://github.com/L3MON4D3/LuaSnip

local function luasnip_build_cmd()
    if vim.fn.executable("make") == 1 then
        return "make install_jsregexp"
    end
    -- Windows：MinGW make 可能不在 Lazy build 时的 PATH（与 basic.lua 探测一致）
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
        local mingw_bins = {}
        local mingw_prefix = vim.env.MINGW_PREFIX
        if mingw_prefix and mingw_prefix ~= "" then
            table.insert(mingw_bins, mingw_prefix:gsub("\\", "/") .. "/bin")
        end
        local program_data = vim.env.ProgramData
        if program_data and program_data ~= "" then
            table.insert(mingw_bins, program_data .. "\\mingw64\\mingw64\\bin")
        end
        local extra = vim.env.NVIM_MINGW_PATHS
        if extra and extra ~= "" then
            for path in extra:gmatch("[^;]+") do
                path = path:gsub("^%s+", ""):gsub("%s+$", "")
                if path ~= "" then
                    table.insert(mingw_bins, path)
                end
            end
        end
        for _, bin in ipairs(mingw_bins) do
            local make_exe = bin:gsub("\\", "/") .. "/make"
            if vim.fn.executable(make_exe) == 1 then
                return "cd deps/jsregexp && PATH=" .. bin .. ";$PATH make"
            end
        end
    end
    return nil
end

return {
    {
        -- 插件名称
        "L3MON4D3/LuaSnip",
        -- 跟随最新发布版本
        -- 从仓库使用的版本
        version = "v2.*", -- 将 <CurrentMajor> 替换为最新发布的主版本号（最新版本的第一个数字）
        -- 构建 jsregexp，消除 checkhealth 警告（占位符转换能力）
        build = luasnip_build_cmd(),
        -- 插件加载时需要加载的依赖插件列表
        dependencies = {
            "rafamadriz/friendly-snippets",
        },
        -- 插件配置
        config = function()
            local ls = require("luasnip")
            
            -- 加载 friendly-snippets
            require("luasnip.loaders.from_vscode").lazy_load()
            
            -- 配置选项
            ls.config.set_config({
                history = true,
                delete_check_events = "TextChanged",
                -- 更频繁地更新，查看 :h events 获取更多信息
                updateevents = "TextChanged,TextChangedI",
            })
        end,
        -- Tab/S-Tab 由 nvim-cmp 统一映射（避免与 cmp 冲突）
    },
}