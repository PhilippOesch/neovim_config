vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		if name == "blink.cmp" and kind == "install" then
			if not ev.data.active then
				vim.cmd.packadd("blink.cmp")
			end
			vim.cmd("BlinkCmp build")
		end
	end,
})

vim.pack.add({
	"https://github.com/tpope/vim-fugitive",
	"https://github.com/tpope/vim-rhubarb",
	"https://github.com/tpope/vim-sleuth",
	"https://github.com/nvim-lua/plenary.nvim",
}, { confirm = false })

require("config.theme")
require("config.general")
require("config.keymaps")

-- Plugins
require("plugins.blink_cmp")
require("plugins.lsp.init")
require("plugins.treesitter")
require("plugins.whichkey")
require("plugins.oil")
require("plugins.autopairs")
require("plugins.snacks")
require("plugins.webdev_icons")
require("plugins.todo_comment")
require("plugins.surround")
require("plugins.smear_nvim")
