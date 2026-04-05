-- return {
vim.pack.add({ "https://github.com/folke/todo-comments.nvim" }, { confirm = false })
require("todo-comments").setup({})

vim.keymap.set("n", "<leader>st", function()
	require("snacks").picker.todo_comments()
end, { noremap = true, desc = "Todo" })
vim.keymap.set("n", "<leader>st", function()
	require("snacks").picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
end, { noremap = true, desc = "Todo/Fix/Fixme" })
