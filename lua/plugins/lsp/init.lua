---@type Config.Plugin
return {
	deps = {
		"https://github.com/pmizio/typescript-tools.nvim",
		"https://github.com/neovim/nvim-lspconfig",
		"https://github.com/williamboman/mason.nvim",
		"https://github.com/williamboman/mason-lspconfig.nvim",
		"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
		"https://github.com/ionide/Ionide-vim",
		"https://github.com/seblj/roslyn.nvim",
		"https://github.com/mfussenegger/nvim-jdtls",
		"https://github.com/folke/lazydev.nvim",
		"https://github.com/L3MON4D3/LuaSnip",
		"https://github.com/rafamadriz/friendly-snippets",
		"https://github.com/kristijanhusak/vim-dadbod-completion"
	},
	init = function()
		local lspHelpers = require("plugins.lsp.utils")

		require("plugins.lsp.libs.typescript-tools")

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),

			callback = function(event)
				lspHelpers.on_attach(event)
			end,
		})

		require("plugins.lsp.setup.mason")
	end,
}
