vim.pack.add({ "https://github.com/mistweaverco/kulala.nvim" }, { confirm = false })
local opts = {
	global_keymaps = false,
	global_keymaps_prefix = "<leader>R",
	kulala_keymaps_prefix = "",
}
require("kulala").setup(opts)
