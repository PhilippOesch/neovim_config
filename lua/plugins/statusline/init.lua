local builder = require("plugins.statusline.builder")

local M = {}

M.setup = function()
	vim.o.statusline = "%{%v:lua.require'plugins.statusline.init'.eval_statusline()%}"
end

local statusline_builder = builder.new()
statusline_builder
	:add_surround("󰽥", "󰽧", function(bld)
		-- :add(function()
		-- 	return "dsgdsg"
		-- end, "Special")
		-- bld:add_hl("Special", function(bld)
		bld:add_mode()
		-- end)
	end, "Normal")
	:add_space()
	:add_filename()

M.eval_statusline = function()
	return statusline_builder:build()
	-- return file_name() .. Align
end

return M
