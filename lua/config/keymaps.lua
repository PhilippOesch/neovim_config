local map = vim.keymap.set

map({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

map({ "t" }, "<Esc>", "<C-\\><C-n> ", { silent = true })

-- Remap for dealing with word wrap
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Go to previous diagnostic message" })
map("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Go to next diagnostic message" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- window split
map("n", "<leader>wv", "<C-w>v", {
	noremap = true,
	desc = "split window vertically",
})
-- window split
map("n", "<leader>wh", "<C-w>s", {
	noremap = true,
	desc = "split window horizontally",
})

-- window navigation
map("n", "<C-h>", "<C-w>h", {
	noremap = true,
	desc = "Window left",
})
map("n", "<C-l>", "<C-w>l", {
	noremap = true,
	desc = "Window right",
})
map("n", "<C-j>", "<C-w>j", {
	noremap = true,
	desc = "Window down",
})
map("n", "<C-k>", "<C-w>k", {
	noremap = true,
	desc = "Window up",
})

local opts = { noremap = true, silent = true }

map("n", "gx", [[:execute '!open ' . shellescape(expand('<cfile>'), 1)<CR>]], opts)

map("x", "p", "P", { silent = true })
map("x", "P", "p", { silent = true })

local ok, oil = pcall(require, 'oil')


local function getBufFileType()
	local bufnr = vim.api.nvim_get_current_buf()
	return vim.bo[bufnr].filetype
end

local function insertFullPath()
	local filepath = nil
	if getBufFileType() == "oil" then
		local file = oil.get_current_dir()
		filepath = vim.fn.fnamemodify(file, ":p")
	else
		filepath = vim.fn.expand("%:p")
	end
	vim.fn.setreg("+", filepath) -- write to clippoard
end

local function insertCwdPath()
	local filepath = nil
	if getBufFileType() == "oil" then
		local file = oil.get_current_dir()
		filepath = vim.fn.fnamemodify(file, ":p:.")
	else
		filepath = vim.fn.expand("%:p:.")
	end
	vim.fn.setreg("+", filepath) -- write to clippoard
end

local function insertFileName()
	local filepath = nil
	if getBufFileType() == "oil" then
		local file = oil.get_current_dir()
		filepath = vim.fn.fnamemodify(vim.fn.fnamemodify(file, ":h"), ":t")
	else
		filepath = vim.fn.expand("%:t")
	end
	vim.fn.setreg("+", filepath) -- write to clippoard
end

local function insertPwd()
	local workingDirPath = vim.fn.getcwd()
	vim.fn.setreg("+", workingDirPath) -- write to clippoard
end

map("n", "<leader>cf", insertFullPath, { noremap = true, desc = "Copy full file path to clipboard." })
map("n", "<leader>cs", insertFileName, { noremap = true, desc = "Copy file name" })
map("n", "<leader>cd", insertPwd, { noremap = true, desc = "Copy current working directory to clipboard." })
map("n", "<leader>cp", insertCwdPath, { noremap = true, desc = "Copy filepath relative to current working directory" })
map("n", "<leader>u", require("undotree").open, {noremap = true, desc = 'undootree'})
