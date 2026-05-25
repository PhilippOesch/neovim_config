local lspHelpers = require("plugins.lsp.utils")

local M = {}

-- install roslyn: dotnet tool install --global roslyn-language-server --prerelease
-- see reference: https://github.com/dotnet/roslyn/blob/main/src/LanguageServer/Microsoft.CodeAnalysis.LanguageServer/README.md

local opts = {
	cmd = {
		"roslyn-language-server",
		"--logLevel", -- this property is required by the server
		"Information",
		"--extensionLogDirectory", -- this property is required by the server
		vim.fs.joinpath(vim.uv.os_tmpdir(), "roslyn_ls/logs"),
		"--stdio",
	},
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
	vim.lsp.config("roslyn_ls", opts)
	vim.lsp.enable("roslyn_ls")
end

return M
