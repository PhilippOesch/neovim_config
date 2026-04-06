vim.pack.add({ "https://github.com/atiladefreitas/dooing" }, { confirm = false })
require("dooing").setup({
	keymap = {
		toggle_window = "<leader>do",
		open_project_todo = "<leader>dO",
	},
})
return {}
