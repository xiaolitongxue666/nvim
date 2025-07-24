-- smear-cursor.nvim

-- Neovim 插件可在所有终端中为光标添加涂抹效果

-- 官方文档：https://github.com/sphamba/smear-cursor.nvim

return {
  "sphamba/smear-cursor.nvim",

  opts = {
    -- 在切换缓冲区或窗口时启用光标拖尾效果
    smear_between_buffers = true,

    -- 在行内移动或移动到相邻行时启用光标拖尾效果
    -- 使用 `min_horizontal_distance_smear` 和 `min_vertical_distance_smear` 进行更精细的控制
    smear_between_neighbor_lines = true,

    -- 滚动时在缓冲区空间而不是屏幕空间中绘制拖尾效果
    scroll_buffer_space = true,

    -- 如果您的字体支持传统计算符号（块状unicode符号），请设置为 `true`
    -- 拖尾效果在所有背景上都会有更好的混合效果
    legacy_computing_symbols_support = false,

    -- 在插入模式下启用光标拖尾效果
    -- 另请参阅 `vertical_bar_cursor_insert_mode` 和 `distance_stop_animating_vertical_bar`
    smear_insert_mode = true,
  },
}