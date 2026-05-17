---@type Config.Plugin
return {
	init = function()
		require("plugins.jest.init").setup()
	end,
}
