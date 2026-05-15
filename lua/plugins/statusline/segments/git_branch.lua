local M = {}

---@param bld Builder
---@param hl? hl_val
function M.add(bld, hl)
	bld:add_conditional(function(bld)
		bld:add(function()
			return " " .. vim.b.gitsigns_status_dict.head
		end, hl)
	end, function()
		return vim.b.gitsigns_head or vim.b.gitsigns_status_dict
	end)
end

return M
