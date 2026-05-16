local highlight = require("plugins.statusline.highlight")

local M = {}

---@param bld Builder
---@param hl? hl_val
function M.add(bld, hl)
	bld:add_conditional(function(bld)
		bld
			:add_hl_start(hl or { fg = highlight.get_highlight("Constant").fg })
			:add("(")
			:add_conditional(function(bld)
				bld:add(function()
					return "+" .. vim.b.gitsigns_status_dict.added
				end, { fg = highlight.get_highlight("Added").fg })
			end, function()
				return vim.b.gitsigns_status_dict.added ~= nil and vim.b.gitsigns_status_dict.added > 0
			end)
			:add_conditional(function(bld)
				bld:add(function()
					return "-" .. vim.b.gitsigns_status_dict.removed
				end, { fg = highlight.get_highlight("Removed").fg })
			end, function()
				return vim.b.gitsigns_status_dict.removed ~= nil and vim.b.gitsigns_status_dict.removed > 0
			end)
			:add_conditional(function(bld)
				bld:add(function()
					return "~" .. vim.b.gitsigns_status_dict.changed
				end, { fg = highlight.get_highlight("Changed").fg })
			end, function()
				return vim.b.gitsigns_status_dict.changed ~= nil and vim.b.gitsigns_status_dict.changed > 0
			end)
			:add(
				")"
			)
			:add_hl_end()
	end, function()
		return vim.b.gitsigns_status_dict ~= nil
	end)
	-- bld:add_conditional(function(bld)
	-- 	bld:add(function()
	-- 		local fmt = vim.bo.fileformat
	-- 		return ' ' .. fmt
	-- 	end, hl)
	-- end, function()
	-- 	return vim.bo.fileformat ~= nil
	-- end)
end

return M
