-- return {
-- 	-- LSP Configuration & Plugins
vim.pack.add({
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/williamboman/mason.nvim",
	"https://github.com/williamboman/mason-lspconfig.nvim",
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
}, { confirm = false })

local lspHelpers = require("plugins.lsp.utils")

-- require("plugins.lsp.libs.typescript-tools")

--other lsps:
vim.pack.add({
	"https://github.com/folke/lazydev.nvim",
	"https://github.com/ionide/Ionide-vim",
	"https://github.com/seblj/roslyn.nvim",
	"https://github.com/mfussenegger/nvim-jdtls",
}, {confirm = false})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),

	callback = function(event)
		lspHelpers.on_attach(event)
	end,
})

require("plugins.lsp.setup.mason")
