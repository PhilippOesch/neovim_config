vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt_global.exrc = true

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local plugins = require("utils.plugin_manager").new({
	"https://github.com/tpope/vim-fugitive",
	"https://github.com/tpope/vim-rhubarb",
	"https://github.com/tpope/vim-sleuth",
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/j-hui/fidget.nvim",
	"https://github.com/esmuellert/vscode-diff.nvim",
	"https://github.com/MunifTanjim/nui.nvim",
	require("plugins.whichkey"),
	require("plugins.todo"),
	require("plugins.webdev_icons"),
	require("plugins.blink_cmp"),
	require("config.theme"),
	require("plugins.comment"),
	require("plugins.autopairs"),
	require("plugins.conform"),
	require("plugins.dadbod"),
	require("plugins.lsp.init"),
	require("plugins.treesitter"),
	require("plugins.gitsigns"),
	require("plugins.harpoon"),
	require("plugins.navic"),
	require("plugins.oil"),
	require("plugins.kulala"),
	require("plugins.snacks"),
	require("plugins.todo_comment"),
	require("plugins.surround"),
	require("plugins.strudel"),
	require("plugins.smear_nvim"),
	require("plugins.obsidian_nvim"),
	require("plugins.markdown_preview"),
	require("plugins.markdown_render"),
	require("plugins.dap.init"),
	require("plugins.neotest"),
	require("plugins.persisted_nvim"),
	require("plugins.nvimcolorizer"),
	require("plugins.codecompanion"),
	require("plugins.heirline.init"),
})

require("config.general")
require("config.keymaps")

plugins:init()
