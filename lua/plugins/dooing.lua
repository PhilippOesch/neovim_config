return {
	"atiladefreitas/dooing",
	config = function()
		require("dooing").setup({
			keymap = {
				toggle_window = "<leader>do",
				open_project_todo = "<leader>dO",
			},
		})
	end,
}
