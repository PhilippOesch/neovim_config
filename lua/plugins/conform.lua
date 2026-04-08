local prettierSetting = { "prettier", "prettierd", stop_after_first = true }

local prettierLanguages = {
	"typescript",
	"typescriptreact",
	"javascript",
	"javascriptreact",
	"vue",
	"css",
	"html",
	"htmlangular",
	"json",
}

local formattingConfig = {}

for _, language in ipairs(prettierLanguages) do
	formattingConfig[language] = prettierSetting
end

formattingConfig.go = { "goimports", "golines", lsp_format = "last", stop_after_first = false }
formattingConfig.xml = { "xmlformatter" }
formattingConfig.python = { "black", stop_after_first = true }
formattingConfig.proj = { "xmlformatter" }
formattingConfig.cs = { "csharpier" }
formattingConfig.lua = { "stylua" }
formattingConfig.yaml = { "yamlfmt" }
formattingConfig["markdown"] = { "prettier", "markdownlint-cli2", "markdown-toc" }
formattingConfig["markdown.mdx"] = { "prettier", "markdownlint-cli2", "markdown-toc" }

require("conform").setup({
	formatters = {
		csharpier = {
			command = "csharpier",
			args = { "format", "--write-stdout" },
			stdin = true,
		},
		["markdown-toc"] = {
			condition = function(_, ctx)
				for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
					if line:find("<!%-%- toc %-%->") then
						return true
					end
				end
			end,
		},
		["markdownlint-cli2"] = {
			condition = function(_, ctx)
				local diag = vim.tbl_filter(function(d)
					return d.source == "markdownlint"
				end, vim.diagnostic.get(ctx.buf))
				return #diag > 0
			end,
		},
	},
	formatters_by_ft = formattingConfig,
	notify_no_formatters = true,
})

-- keymaps
vim.keymap.set("n", "<leader>fm", function()
	require("conform").format({ async = true, lsp_fallback = true })
end, {
	noremap = true,
	desc = "Format",
})
vim.keymap.set("v", "<leader>fm", function()
	require("conform").format({ async = true, lsp_fallback = true })
end, {
	noremap = true,
	desc = "Format visual mode",
})
