vim.pack.add({ "https://github.com/windwp/nvim-autopairs" }, { confirm = false })
require("nvim-autopairs").setup({
	disable_filetype = { "TelescopePrompt", "spectre_panel", "snacks_picker_input", "codecompanion" },
})
