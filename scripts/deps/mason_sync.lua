-- Headless Mason 预同步（由 sync_mason.sh 通过 :luafile 调用）
-- 环境变量：NVIM_MASON_PKG_LIST（空格分隔包名）、NVIM_MASON_WAIT_MS（默认 600000）

local pkg_list = os.getenv("NVIM_MASON_PKG_LIST") or ""
local packages = {}
for name in pkg_list:gmatch("%S+") do
    table.insert(packages, name)
end

if #packages == 0 then
    vim.api.nvim_err_writeln("[mason_sync] NVIM_MASON_PKG_LIST is empty")
    vim.cmd("cquit 1")
end

local max_ms = tonumber(os.getenv("NVIM_MASON_WAIT_MS") or "600000") or 600000

vim.wait(30000, function()
    return package.loaded["lazy"] ~= nil
end, 200)

vim.cmd("Lazy! load mason.nvim mason-lspconfig.nvim mason-tool-installer.nvim")
vim.cmd("MasonUpdate")

local registry = require("mason-registry")

local function pending_count()
    local missing = 0
    local installing = 0
    for _, name in ipairs(packages) do
        local ok, pkg = pcall(registry.get_package, name)
        if not ok then
            missing = missing + 1
        elseif pkg:is_installing() then
            installing = installing + 1
        elseif not pkg:is_installed() then
            missing = missing + 1
        end
    end
    return missing, installing
end

local function all_ready()
    local missing, installing = pending_count()
    return missing == 0 and installing == 0
end

vim.wait(max_ms, function()
    return all_ready()
end, 1000)

if not all_ready() then
    local missing, installing = pending_count()
    vim.api.nvim_err_writeln(
        string.format("[mason_sync] timeout: %d missing, %d installing", missing, installing)
    )
    vim.cmd("cquit 1")
end

vim.cmd("qall!")
