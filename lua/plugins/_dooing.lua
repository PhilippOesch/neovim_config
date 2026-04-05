-- return {
-- 	"atiladefreitas/dooing",
-- 	config = function()
-- 		require("dooing").setup({
-- 			keymap = {
-- 				toggle_window = "<leader>do",
-- 				open_project_todo = "<leader>dO",
-- 			},
-- 		})
-- 	end,
-- }

vim.pack.add({ "https://github.com/atiladefreitas/dooing" })
require("dooing").setup({
	keymap = {
		toggle_window = "<leader>do",
		open_project_todo = "<leader>dO",
	},
})
return {}
