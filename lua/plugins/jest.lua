---@type Config.Plugin
return {
	init = function()
		require("plugins.test-runner.init").setup({
			sidebar_width = 60,
		})
	end,
}
