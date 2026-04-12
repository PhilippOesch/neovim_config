---@type Config.Plugin
return {
	deps = {
		"https://github.com/nvim-tree/nvim-web-devicons",
	},
	init = function()
		require("nvim-web-devicons").setup({})
	end,
}
