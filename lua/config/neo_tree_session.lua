--- neo-tree 与会话（persistence/mks）协作：sidecar JSON + 保存前关闭、加载后重建。
local M = {}

M._loaded_session_path = nil

local function normalize_session_path(session_vim_path)
	if not session_vim_path or session_vim_path == "" then
		return nil
	end
	return vim.fn.fnamemodify(session_vim_path, ":p")
end

local function sidecar_path(session_vim_path)
	local normalized = normalize_session_path(session_vim_path)
	if not normalized then
		return nil
	end
	return normalized:gsub("%.vim$", ".neo-tree.json")
end

local function read_sidecar(session_vim_path)
	local path = sidecar_path(session_vim_path)
	if not path or vim.fn.filereadable(path) ~= 1 then
		return nil
	end
	local lines = vim.fn.readfile(path)
	if not lines or #lines == 0 then
		return nil
	end
	local ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
	if not ok or type(decoded) ~= "table" then
		return nil
	end
	return decoded
end

local function write_sidecar(session_vim_path, payload)
	local path = sidecar_path(session_vim_path)
	if not path then
		return false
	end
	vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
	local json = vim.json.encode(payload)
	local ok = pcall(vim.uv.fs_write, path, json)
	if not ok then
		ok = pcall(vim.fn.writefile, { json }, path)
	end
	return ok
end

local function delete_sidecar(session_vim_path)
	local path = sidecar_path(session_vim_path)
	if path and vim.fn.filereadable(path) == 1 then
		pcall(vim.fn.delete, path)
	end
end

function M.collect_visible_windows()
	local entries = {}
	local seen = {}
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype == "neo-tree" then
			local position = vim.b[buf].neo_tree_position or "left"
			local source = vim.b[buf].neo_tree_source or "filesystem"
			local key = source .. "@" .. position
			if not seen[key] then
				seen[key] = true
				entries[#entries + 1] = { source = source, position = position }
			end
		end
	end
	return entries
end

--- session 恢复的 neo-tree 不在 manager 状态里，command close 无效，须强制删窗/buffer
function M.purge_neo_tree_artifacts()
	pcall(function()
		require("neo-tree.command").execute({ action = "close" })
	end)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype == "neo-tree" then
			pcall(vim.api.nvim_win_close, win, true)
		end
	end
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
			pcall(vim.api.nvim_buf_delete, buf, { force = true })
		end
	end
end

function M.save()
	local persistence = require("persistence")
	local session_path = normalize_session_path(persistence.current())
	if not session_path then
		return
	end
	local entries = M.collect_visible_windows()
	if #entries == 0 then
		delete_sidecar(session_path)
		return
	end
	write_sidecar(session_path, {
		dir = vim.uv.cwd(),
		windows = entries,
	})
	M.purge_neo_tree_artifacts()
end

local function resolve_session_path()
	return normalize_session_path(M._loaded_session_path or vim.v.this_session)
end

local function neo_tree_has_tree_content()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].filetype == "neo-tree" then
			local ok, source = pcall(vim.api.nvim_buf_get_var, buf, "neo_tree_source")
			if not ok or not source then
				return false
			end
			local line_count = vim.api.nvim_buf_line_count(buf)
			if line_count <= 1 then
				return false
			end
			local lines = vim.api.nvim_buf_get_lines(buf, 0, math.min(line_count, 50), false)
			for _, line in ipairs(lines) do
				if line:match("%S") and not line:match("^%s*%-+%s*$") then
					return true
				end
			end
			return false
		end
	end
	return false
end

local function reopen_windows(dir, windows)
	require("neo-tree")
	local command = require("neo-tree.command")
	for _, entry in ipairs(windows) do
		command.execute({
			action = "focus",
			source = entry.source,
			position = entry.position,
			dir = dir,
		})
	end
	if package.loaded["neo-tree.sources.manager"] then
		local manager = require("neo-tree.sources.manager")
		for _, entry in ipairs(windows) do
			pcall(manager.refresh, entry.source)
		end
	end
end

local function default_windows()
	return { { source = "filesystem", position = "left" } }
end

local function force_restore(dir, windows, retry)
	M.purge_neo_tree_artifacts()
	vim.defer_fn(function()
		reopen_windows(dir, windows)
		if retry and not neo_tree_has_tree_content() then
			vim.defer_fn(function()
				M.purge_neo_tree_artifacts()
				reopen_windows(dir, windows)
			end, 250)
		end
	end, 80)
end

local restore_scheduled = false

local function run_restore(retry)
	local session_path = resolve_session_path()
	M._loaded_session_path = nil

	local data = session_path and read_sidecar(session_path) or nil
	local windows = (data and data.windows) or M.collect_visible_windows()
	if not windows or #windows == 0 then
		windows = default_windows()
	end

	local dir = (data and data.dir) or vim.uv.cwd()
	if dir == "" or vim.fn.isdirectory(dir) ~= 1 then
		dir = vim.uv.cwd()
	end

	force_restore(dir, windows, retry)
end

function M.restore()
	if restore_scheduled then
		return
	end
	restore_scheduled = true
	vim.defer_fn(function()
		restore_scheduled = false
		run_restore(true)
	end, 300)
end

function M.find_latest_session_with_sidecar()
	for _, session in ipairs(require("persistence").list()) do
		if read_sidecar(session) then
			return session
		end
	end
	return nil
end

function M.load_session_file(session_file)
	if not session_file or vim.fn.filereadable(session_file) ~= 1 then
		return false
	end
	local persistence = require("persistence")
	M._loaded_session_path = normalize_session_path(session_file)
	persistence.fire("LoadPre")
	vim.cmd("silent! source " .. vim.fn.fnameescape(session_file))
	persistence.fire("LoadPost")
	return true
end

---@param opts? { last?: boolean, prefer_sidecar?: boolean }
function M.load_session(opts)
	opts = opts or {}
	local persistence = require("persistence")
	local session_file = nil

	if opts.prefer_sidecar then
		session_file = M.find_latest_session_with_sidecar()
	end

	if session_file then
		M.load_session_file(session_file)
		return
	end

	if opts.last then
		persistence.load({ last = true })
	else
		persistence.load()
	end
end

function M.setup_autocmds()
	local group = vim.api.nvim_create_augroup("neo_tree_session", { clear = true })
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "PersistenceSavePre",
		callback = function()
			M.save()
		end,
	})
	-- 仅在 LoadPost 恢复（SessionLoadPost 过早且与 neo-tree 内置 clean 竞态）
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "PersistenceLoadPost",
		callback = function()
			M.restore()
		end,
	})
end

return M
