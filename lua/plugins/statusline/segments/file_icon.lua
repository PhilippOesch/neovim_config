local web_icons_available, web_icons = pcall(require, "nvim-web-devicons")

local M = {}

---@param bld Builder
---@param hl? hl_val
function M.add(bld)
	bld:add_conditional(function(bld)
		bld:add(function()
			local filename = vim.api.nvim_buf_get_name(0)
			local extension = vim.fn.fnamemodify(filename, ":e")
			local icon, _ = web_icons.get_icon_color(filename, extension, { default = true })
			return icon
		end, function()
			local filename = vim.api.nvim_buf_get_name(0)
			local extension = vim.fn.fnamemodify(filename, ":e")
			local _, icon_color = web_icons.get_icon_color(filename, extension, { default = true })
			return { fg = icon_color }
		end)
	end, function()
		return web_icons_available
	end)
end

return M
