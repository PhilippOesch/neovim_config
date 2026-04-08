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
require("render-markdown").setup(opts)
