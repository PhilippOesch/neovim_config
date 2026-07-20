---@type Config.Plugin
return {
	deps = {
		"git@github.com:PhilippOesch/testreport.nvim.git",
		-- {
		-- 	src = "git@github.com:PhilippOesch/testreport.nvim.git",
		-- 	version = "feat/allow-specifiying-adapter-on-run-tests",
		-- },
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

		vim.api.nvim_create_user_command("TestReportRun", function(opts)
			if opts.args and opts.args ~= "" then
				require("testreport").run_file(opts.args)
			else
				require("testreport").run_file()
			end
		end, { nargs = "?" })
	end,
}
