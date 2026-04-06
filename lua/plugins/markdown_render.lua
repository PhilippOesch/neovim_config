vim.pack.add({ "https://github.com/MeanderingProgrammer/render-markdown.nvim" }, { confirm = false })
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
