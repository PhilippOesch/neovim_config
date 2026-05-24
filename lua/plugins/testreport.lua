---@type Config.Plugin
return {
	deps = {
		"git@github.com:PhilippOesch/testreport.nvim.git",
	},
	init = function()
		require("testreport").setup({
			sidebar_width = 60,
		})

		vim.keymap.set(
			"n",
			"<leader>tef",
			require("testreport").run_file,
			{ noremap = true, silent = true, desc = "Run tests for current file" }
		)
		vim.keymap.set(
			"n",
			"<leader>tet",
			require("testreport").toggle_sidebar,
			{ noremap = true, silent = true, desc = "Toggle test results sidebar" }
		)
	end,
}
