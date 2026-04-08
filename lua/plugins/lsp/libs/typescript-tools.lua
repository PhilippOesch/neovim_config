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
