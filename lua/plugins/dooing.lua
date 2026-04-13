---@type Config.Plugin
return {
	init = function()
		local todo = require("plugins.todo.init")
		todo.setup()
	end,
}
