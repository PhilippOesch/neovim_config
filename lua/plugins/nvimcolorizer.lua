---@type Config.Plugin
return {
	specs = {
		"https://github.com/norcalli/nvim-colorizer.lua",
	},
	init = function()
		vim.o.termguicolors = true
		require("colorizer").setup({
			"css",
			"lua",
			"md",
			"javascript",
			html = {
				mode = "foreground",
			},
		})
	end,
}
