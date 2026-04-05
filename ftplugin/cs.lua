local opts = {
	-- - "off": Hack to turn off all filewatching. (Can be used if you notice performance issues)
	filewatching = "roslyn",
	-- your configuration comes here; leave empty for default settings
}
require("roslyn").setup(opts)
