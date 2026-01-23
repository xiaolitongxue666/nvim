-- 智能窗口控制模块
-- 提供更好的窗口大小和位置管理

local M = {}

-- 窗口类型识别
local function get_window_type()
    local buftype = vim.bo.buftype
    local filetype = vim.bo.filetype
    
    if buftype == "nofile" then
        if filetype == "outline" then
            return "outline"
        elseif filetype == "neo-tree" then
            return "neo-tree"
        elseif filetype == "toggleterm" then
            return "terminal"
        elseif filetype == "qf" then
            return "quickfix"
        end
    end
    
    return "normal"
end



-- 智能窗口大小调整
local function smart_resize(direction, amount)
    local window_type = get_window_type()
    
    -- 对于插件窗口，使用更保守的调整策略
    if window_type == "outline" or window_type == "neo-tree" then
        if direction == "width" then
            local current_width = vim.api.nvim_win_get_width(0)
            local total_width = vim.o.columns
            
            -- 计算合理的调整范围
            local min_width, max_width
            if window_type == "outline" then
                min_width = 30
                max_width = math.floor(total_width * 0.35)  -- 更保守的最大宽度
            else  -- neo-tree
                min_width = 35
                max_width = math.floor(total_width * 0.45)  -- 更保守的最大宽度
            end
            
            -- 使用更小的步长
            local step = math.max(-2, math.min(2, amount))  -- 限制步长在-2到2之间
            
            local new_width = math.max(min_width, math.min(max_width, current_width + step))
            vim.api.nvim_win_set_width(0, new_width)
        elseif direction == "height" then
            -- 插件窗口高度调整使用标准方法
            vim.cmd("resize " .. amount)
        end
    else
        -- 普通窗口：检查是否有插件窗口相邻，如果有则调整插件窗口
        if direction == "width" then
            -- 查找相邻的插件窗口
            local current_win = vim.api.nvim_get_current_win()
            local wins = vim.api.nvim_list_wins()
            local plugin_win = nil
            
            for _, win in ipairs(wins) do
                if win ~= current_win then
                    local buf = vim.api.nvim_win_get_buf(win)
                    local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
                    if filetype == "outline" or filetype == "neo-tree" then
                        plugin_win = win
                        break
                    end
                end
            end
            
            if plugin_win then
                -- 如果找到插件窗口，调整它而不是当前窗口
                local plugin_buf = vim.api.nvim_win_get_buf(plugin_win)
                local plugin_filetype = vim.api.nvim_buf_get_option(plugin_buf, "filetype")
                local plugin_width = vim.api.nvim_win_get_width(plugin_win)
                local total_width = vim.o.columns
                
                -- 计算插件窗口的调整范围
                local min_width, max_width
                if plugin_filetype == "outline" then
                    min_width = 30
                    max_width = math.floor(total_width * 0.35)
                else  -- neo-tree
                    min_width = 35
                    max_width = math.floor(total_width * 0.45)
                end
                
                -- 使用更小的步长
                local step = math.max(-2, math.min(2, amount))
                local new_width = math.max(min_width, math.min(max_width, plugin_width - step))  -- 注意这里是减号
                vim.api.nvim_win_set_width(plugin_win, new_width)
            else
                -- 如果没有插件窗口，使用标准调整
                vim.cmd("vertical resize " .. amount)
            end
        elseif direction == "height" then
            vim.cmd("resize " .. amount)
        end
    end
end

-- 窗口大小预设
local window_presets = {
    outline = {
        narrow = 32,
        normal = 35,
        wide = 38,
    },
    neo_tree = {
        narrow = 38,
        normal = 42,
        wide = 48,
    },
    terminal = {
        small = 15,
        normal = 25,
        large = 40,
    },
}

-- 设置窗口大小预设
function M.set_window_preset(window_type, preset)
    local presets = window_presets[window_type]
    if not presets or not presets[preset] then
        return
    end
    
    local width = presets[preset]
    vim.api.nvim_win_set_width(0, width)
end

-- 智能窗口调整函数
function M.smart_resize_height(amount)
    smart_resize("height", amount)
end

function M.smart_resize_width(amount)
    smart_resize("width", amount)
end

-- 快速调整到预设大小
function M.resize_to_preset(preset)
    local window_type = get_window_type()
    M.set_window_preset(window_type, preset)
end

-- 平衡窗口大小
function M.balance_windows()
    vim.cmd("wincmd =")
end

-- 最大化当前窗口
function M.maximize_window()
    vim.cmd("wincmd |")
end

-- 恢复窗口布局
function M.restore_layout()
    vim.cmd("wincmd =")
end


-- 设置窗口控制快捷键
function M.setup_keymaps()
    local map = vim.api.nvim_set_keymap
    local opt = { noremap = true, silent = true }
    
    -- 智能窗口大小调整（更精细的控制）
    map("n", "<C-Up>", ":lua require('window_control').smart_resize_height(3)<CR>", opt)
    map("n", "<C-Down>", ":lua require('window_control').smart_resize_height(-3)<CR>", opt)
    map("n", "<C-Left>", ":lua require('window_control').smart_resize_width(-3)<CR>", opt)
    map("n", "<C-Right>", ":lua require('window_control').smart_resize_width(3)<CR>", opt)
    
    -- 快速预设调整
    map("n", "<leader>wn", ":lua require('window_control').resize_to_preset('narrow')<CR>", opt)
    map("n", "<leader>wN", ":lua require('window_control').resize_to_preset('normal')<CR>", opt)
    map("n", "<leader>ww", ":lua require('window_control').resize_to_preset('wide')<CR>", opt)
    
    -- 窗口管理
    map("n", "<leader>wb", ":lua require('window_control').balance_windows()<CR>", opt)
    map("n", "<leader>wm", ":lua require('window_control').maximize_window()<CR>", opt)
    map("n", "<leader>wr", ":lua require('window_control').restore_layout()<CR>", opt)
    
    -- 禁用原来的箭头键调整（可选）
    -- map("n", "<Up>", "<Nop>", opt)
    -- map("n", "<Down>", "<Nop>", opt)
    -- map("n", "<Left>", "<Nop>", opt)
    -- map("n", "<Right>", "<Nop>", opt)
end

return M
