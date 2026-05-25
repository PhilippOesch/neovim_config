return {
	deps = {
		"https://github.com/L3MON4D3/LuaSnip",
		"https://github.com/rafamadriz/friendly-snippets",
		"https://github.com/kristijanhusak/vim-dadbod-completion",
	},
	init = function()
		local luasnip = require("luasnip")

		luasnip.filetype_extend("javascriptreact", { "html" })
		luasnip.filetype_extend("typescriptreact", { "html" })
		luasnip.filetype_extend("htmlangular", { "html" })
		luasnip.filetype_extend("vue", { "html" })
		luasnip.filetype_extend("todo", { "markdown" })

		require("luasnip.loaders.from_vscode").lazy_load()
		require("luasnip.loaders.from_vscode").load({ paths = { "./snippets" } })

		require("plugins.custom_sources.init").setup()

		vim.lsp.enable("custom_source_ls")
	end,
}
