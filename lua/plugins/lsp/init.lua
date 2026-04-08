-- return {
-- 	-- LSP Configuration & Plugins
local lspHelpers = require("plugins.lsp.utils")

-- require("plugins.lsp.libs.typescript-tools")

--other lsps:
vim.pack.add({
}, {confirm = false})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),

	callback = function(event)
		lspHelpers.on_attach(event)
	end,
})

require("plugins.lsp.setup.mason")
