return {
	-- LSP Configuration & Plugins
	"neovim/nvim-lspconfig",
	dependencies = {
		-- Automatically install LSPs to stdpath for neovim
		{
			"williamboman/mason.nvim",
			config = true,
			dependencies = {
				"WhoIsSethDaniel/mason-tool-installer.nvim",
			},
			"saghen/blink.cmp",
		},
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		{ "j-hui/fidget.nvim", opts = {} },
		{ import = "plugins.lsp.libs" },
	},
	config = function()
		local lspHelpers = require("plugins.lsp.utils")
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),

			callback = function(event)
				lspHelpers.on_attach(event)
			end,
		})

		require("plugins.lsp.setup.mason")
	end,
}
