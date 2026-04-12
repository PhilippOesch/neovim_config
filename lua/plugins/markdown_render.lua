local opts = {
	heading = {
		-- sign = false,
		-- icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
		icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
	},
	code = {
		sign = false,
		width = "block",
		right_pad = 1,
	},
	file_types = { "markdown", "codecompanion" },
}

---@type Config.Plugin
return {
	deps = {
		"https://github.com/MeanderingProgrammer/render-markdown.nvim",
	},
	init = function()
		require("render-markdown").setup(opts)
	end,
}
