
local M = {}

function M.init()
	local autocmd = vim.api.nvim_create_autocmd

	-- dont list quickfix buffers
	autocmd({ "BufNewFile", "BufRead" }, {
		pattern = "*.fs,*.fsx,*.fsi",
		command = [[set filetype=fsharp]],
	})

	vim.lsp.config("ionide", {})
	vim.lsp.enable("ionide")
end

return M
