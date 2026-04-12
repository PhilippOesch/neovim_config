---@type Config.Plugin
return {
	specs = {
		"https://github.com/echasnovski/mini.surround",
	},
	init = function()
		require("mini.surround").setup()
	end,
}
