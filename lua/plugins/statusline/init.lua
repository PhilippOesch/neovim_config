local builder = require("plugins.statusline.builder")
local highlight = require("plugins.statusline.highlight")

local M = {}

M.setup = function()
	vim.o.statusline = "%{%v:lua.require'plugins.statusline.init'.eval_statusline()%}"
end

local statusline_builder = builder.new()
statusline_builder
	:add_surround("", "", function(bld)
		return bld:add_mode()
	end, { fg = highlight.get_highlight("Folded").bg })
	:add_space()
	:add_conditional(function(bld)
		return bld:add_filename()
	end, function()
		return vim.fn.mode(1) == "n"
	end)
-- :add_filename()

M.eval_statusline = function()
	return statusline_builder:build()
	-- return file_name() .. Align
end

return M
