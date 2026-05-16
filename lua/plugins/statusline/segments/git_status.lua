local M = {}

---@param bld Builder
---@param hl? hl_val
function M.add(bld, hl)
	bld:add_conditional(function(bld)
		bld:add_hl_start(hl or { fg = bld.ctx:get_highlight("Constant").fg })
			:add("(")
			:add_conditional(function(bld)
				bld:add(function()
					return "+" .. bld.ctx:get_git_status().added
				end, { fg = bld.ctx:get_highlight("Added").fg })
			end, function()
				local status = bld.ctx:get_git_status()
				return status ~= nil and status.added ~= nil and status.added > 0
			end)
			:add_conditional(function(bld)
				bld:add(function()
					return "-" .. bld.ctx:get_git_status().removed
				end, { fg = bld.ctx:get_highlight("Removed").fg })
			end, function()
				local status = bld.ctx:get_git_status()
				return status ~= nil and status.removed ~= nil and status.removed > 0
			end)
			:add_conditional(function(bld)
				bld:add(function()
					return "~" .. bld.ctx:get_git_status().changed
				end, { fg = bld.ctx:get_highlight("Changed").fg })
			end, function()
				local status = bld.ctx:get_git_status()
				return status ~= nil and status.changed ~= nil and status.changed > 0
			end)
			:add(")")
			:add_hl_end()
	end, function()
		return bld.ctx:get_git_status() ~= nil
	end)
end

return M
