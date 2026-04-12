---@type Config.Plugin
return {
	specs = {
		"https://github.com/atiladefreitas/dooing",
	},
	init = function()
		require("dooing").setup({})

		vim.keymap.set(
			"n",
			"<leader>do",
			require("dooing").open_global_todo,
			{ noremap = true, desc = "open global todos" }
		)
		vim.keymap.set(
			"n",
			"<leader>dO",
			require("dooing").open_project_todo,
			{ noremap = true, desc = "open project todos" }
		)
	end,
}
