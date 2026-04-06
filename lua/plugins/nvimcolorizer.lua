-- return {
vim.pack.add({ "https://github.com/norcalli/nvim-colorizer.lua" }, { confirm = false })

vim.o.termguicolors = true
require("colorizer").setup({
	"css",
	"lua",
	"md",
	"javascript",
	html = {
		mode = "foreground",
	},
})
