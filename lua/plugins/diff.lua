----@type Config.Plugin
return {
	deps = {
		"https://github.com/esmuellert/codediff.nvim",
	},
	init = function()
		require("codediff").setup({
			diff = {
				ignore_trim_whitespace = true,
			},
		})
	end,
} --@type Config.Plugin
