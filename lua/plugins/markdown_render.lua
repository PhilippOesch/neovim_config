return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = {
		{ "nvim-tree/nvim-web-devicons", opt = true },
		{ "nvim-treesitter/nvim-treesitter" },
	},
	ft = { "markdown", "codecompanion" },
	opts = {
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
	},
	config = function(_, opts)
		require("render-markdown").setup(opts)
	end,
}
