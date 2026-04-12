---@type Config.Plugin
return {
	deps = {
		"https://github.com/echasnovski/mini.surround",
	},
	init = function()
		require("mini.surround").setup()
	end,
}
