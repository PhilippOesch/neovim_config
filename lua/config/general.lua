-- Set highlight on search
vim.o.hlsearch = true

-- Make line numbers default
vim.wo.relativenumber = true
vim.wo.number = true

vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- Enable mouse mode
vim.o.mouse = "a"

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = "unnamedplus"

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 200
vim.o.timeoutlen = 300
vim.o.splitright = true

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})

local quickfixgrp
vim.api.nvim_create_augroup("quickfix", { clear = true })
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
	callback = function()
		vim.cmd([[copen]])
	end,
	group = quickfixgrp,
})

vim.opt.swapfile = false
vim.opt.spelllang = "en_us"

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.bo.softtabstop = 4

vim.o.background = "dark"
vim.opt.cursorline = true

-- just one global status line
--
vim.o.laststatus = 3

vim.cmd.colorscheme("tokyonight")
vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "red" })

vim.g.netrw_sort_options = "i"

-- for some reason shellslash is being reset to true
