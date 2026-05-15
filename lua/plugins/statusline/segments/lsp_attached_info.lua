local M = {}

---@param bld Builder
---@param hl? hl_val
function M.add(bld, hl)
	bld:add_conditional(function(bld)
		bld:add(function()
			local names = {}
			for _, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
				table.insert(names, server.name)
			end
			return "󰣖 " .. table.concat(names, ",") .. ""
		end, hl)
	end, function()
		return next(vim.lsp.get_clients({ bufnr = 0 })) ~= nil
	end)
end

return M
