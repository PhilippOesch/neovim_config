local vue_ls_share = vim.fn.expand("$MASON/packages/vue-language-server")
local vue_language_server_path = vue_ls_share .. "/node_modules/@vue/language-server"

return {
	"pmizio/typescript-tools.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
	config = function()
		require("typescript-tools").setup({
			settings = {
				tsserver_plugins = {
					"@vue/typescript-plugin",
				},
				tsserver_max_memory = 4096,
			},
			filetypes = {
				"javascript",
				"javascriptreact",
				"javascript.jsx",
				"typescript",
				"typescriptreact",
				"typescript.tsx",
				"vue",
			},
		})
	end,
}
