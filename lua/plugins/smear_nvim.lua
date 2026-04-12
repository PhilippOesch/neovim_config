---@type Config.Plugin
return {
	deps = {
		"https://github.com/sphamba/smear-cursor.nvim",
	},
	init = function()
		require("smear_cursor").setup({})
	end,
}
