local builder = require("plugins.statusline.builder")
local highlight = require("plugins.statusline.highlight")

---@class my_statusline.config
---@field statusline? fun(builder: Builder)

local M = {}

local statusline_builder

---@param opts my_statusline.config
M.setup = function(opts)
	if opts.statusline then
		statusline_builder = builder.new()
		opts.statusline(statusline_builder)
		vim.o.statusline = "%{%v:lua.require'plugins.statusline.init'.eval_statusline()%}"
	else
		vim.notify("No statusline configuration available", vim.log.levels.WARN)
	end
end

M.eval_statusline = function()
	if statusline_builder then
		return statusline_builder:build()
	end
end

return M
