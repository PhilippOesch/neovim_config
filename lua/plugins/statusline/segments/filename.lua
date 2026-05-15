local M = {}

---@param bld Builder
---@param hl? hl_val
function M.add(bld, hl)
	bld:add(function()
		return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
	end, hl)
end

return M
