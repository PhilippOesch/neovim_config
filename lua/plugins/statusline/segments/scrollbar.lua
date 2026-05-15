local M = {}

local scroll_bar = { " ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }

---@param bld Builder
---@param hl? hl_val
function M.add(bld, hl)
	bld:add(function()
		local curr_line = vim.api.nvim_win_get_cursor(0)[1]
		local lines = vim.api.nvim_buf_line_count(0)
		local i = math.floor((curr_line - 1) / lines * #scroll_bar) + 1
		return string.rep(scroll_bar[i], 2)
	end, hl)
end

return M
