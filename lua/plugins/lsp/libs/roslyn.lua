return {
	"seblj/roslyn.nvim",
	ft = "cs",
	opts = {
		-- - "off": Hack to turn off all filewatching. (Can be used if you notice performance issues)
		filewatching = "roslyn",
		-- your configuration comes here; leave empty for default settings
	},
	config = function(_, opts)
		require("roslyn").setup(opts)
	end,
}
