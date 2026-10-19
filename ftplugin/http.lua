vim.keymap.set("n", "<leader>Rs", function()
	vim.cmd("Rest run")
end, { buffer = true, desc = "Run HTTP request under cursor" })
vim.keymap.set("n", "<leader>Rb", function()
	vim.cmd("enew")
	vim.bo.buftype = "nofile"
	vim.bo.bufhidden = "wipe"
	vim.bo.swapfile = false
	vim.bo.filetype = "http"
end, { buffer = true, desc = "Open an unsaved HTTP scratch buffer" })
