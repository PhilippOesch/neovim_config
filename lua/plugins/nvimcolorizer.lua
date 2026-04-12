---@type Config.Plugin
return {
	deps = {
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
