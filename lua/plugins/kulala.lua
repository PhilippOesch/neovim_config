---@type Config.Plugin
return {
	specs = {
		"https://github.com/mistweaverco/kulala.nvim",
	},
	init = function()
		local opts = {
			global_keymaps = false,
			global_keymaps_prefix = "<leader>R",
			kulala_keymaps_prefix = "",
		}
		require("kulala").setup(opts)
	end,
}
