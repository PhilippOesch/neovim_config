local M = {}

function M.init()
	vim.lsp.config("eslint", {})
	vim.lsp.enable("eslint")
end

return M
