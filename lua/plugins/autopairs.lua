---@type Config.Plugin
return {
	specs = {
		"https://github.com/windwp/nvim-autopairs",
	},
	init = function()
		require("nvim-autopairs").setup({
			disable_filetype = { "TelescopePrompt", "spectre_panel", "snacks_picker_input", "codecompanion" },
		})
	end,
}
