local M = {}

---@param bld Builder
---@param hl? hl_val
function M.add(bld, hl)
	bld:add_conditional(function(bld)
		bld:add(function()
			return " " .. bld.ctx:get_git_branch()
		end, hl)
	end, function()
		return bld.ctx:get_git_branch() ~= nil
	end)
end

return M
