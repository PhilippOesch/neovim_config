local lspHelpers = require("plugins.lsp.utils")

local M = {}

local opts = {
	settings = {
		["csharp|inlay_hints"] = {
			csharp_enable_inlay_hints_for_implicit_object_creation = true,
			csharp_enable_inlay_hints_for_implicit_variable_types = true,
		},
		["csharp|code_lens"] = {
			dotnet_enable_references_code_lens = true,
		},
	},
}

function M.init()
	opts.capabilities = vim.tbl_deep_extend("force", {}, lspHelpers.capabilities, opts.capabilities or {})
	vim.lsp.config("roslyn", opts)
	vim.lsp.enable("roslyn")
end

return M
