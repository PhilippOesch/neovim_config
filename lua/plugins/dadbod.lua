vim.pack.add({
	"https://github.com/tpope/vim-dadbod",
	"https://github.com/kristijanhusak/vim-dadbod-ui",
	"https://github.com/kristijanhusak/vim-dadbod-completion",
}, { confirm = false })

vim.g.db_ui_use_nerd_fonts = 1
vim.g.db_ui_winwidth = 45
vim.g.db_ui_win_position = "right"
vim.g.db_ui_auto_execute_table_helpers = 1
vim.g.db_ui_use_nvim_notify = 1

vim.api.nvim_create_user_command("DBUIT", "tab DBUI", { desc = "open DBUI" })
