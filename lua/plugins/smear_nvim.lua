---@type Config.Plugin
return {
	specs = {
		"https://github.com/sphamba/smear-cursor.nvim",
	},
	init = function()
		require("smear_cursor").setup({})
	end,
}
