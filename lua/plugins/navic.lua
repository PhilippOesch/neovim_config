---@type Config.Plugin
return {
	deps = {
		"https://github.com/SmiteshP/nvim-navic",
	},
	init = function()
		require("nvim-navic").setup({})
	end,
}
