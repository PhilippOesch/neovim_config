---@type Config.Plugin
return {
	specs = {
		"https://github.com/SmiteshP/nvim-navic",
	},
	init = function()
		require("nvim-navic").setup({})
	end,
}
