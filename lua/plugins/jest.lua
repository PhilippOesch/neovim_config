---@type Config.Plugin
return {
	init = function()
		require("plugins.jest.init").setup({
			sidebar_width = 60,
		})
	end,
}
