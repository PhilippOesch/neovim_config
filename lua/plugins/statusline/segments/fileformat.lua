local M = {}

---@param bld Builder
---@param hl? hl_val
function M.add(bld, hl)
	bld:add_conditional(function(bld)
		bld:add(function()
			local fmt = vim.bo.fileformat
			return ' ' .. fmt
		end, hl)
	end, function()
		return vim.bo.fileformat ~= nil
	end)
end

return M
