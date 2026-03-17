local conditions = require("heirline.conditions")

local LSPActive = {
	condition = conditions.lsp_attached,
	update = { "LspAttach", "LspDetach" },

	-- You can keep it simple,
	-- provider = " [LSP]",

	-- Or complicate things a bit and get the servers names
	provider = function()
		local names = {}
		for _, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
			table.insert(names, server.name)
		end
		return "󰣖 " .. table.concat(names, " ") .. ""
	end,
	hl = { fg = "green", bold = true },
}

local LSPMessages = {
	-- condition = function ()
	-- 	return vim.lsp.status() ~= nil
	-- end,
	provider = vim.lsp.status(),
	hl = { fg = "gray" },
}

local diagnostics_icons = {
	[vim.diagnostic.severity.ERROR] = "",
	[vim.diagnostic.severity.WARN] = "",
	[vim.diagnostic.severity.INFO] = "󰋇",
	[vim.diagnostic.severity.HINT] = "󰌵",
}

local Diagnostics = {

	condition = conditions.has_diagnostics,

	init = function(self)
		self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
		self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
		self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
		self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
	end,

	update = { "DiagnosticChanged", "BufEnter" },

	{
		provider = function(self)
			-- 0 is just another output, we can decide to print it or not!
			return self.errors > 0 and (diagnostics_icons[vim.diagnostic.severity.ERROR] .. ":" .. self.errors .. " ")
		end,
		hl = { fg = "diag_error" },
	},
	{
		provider = function(self)
			return self.warnings > 0
				and (diagnostics_icons[vim.diagnostic.severity.WARN] .. ":" .. self.warnings .. " ")
		end,
		hl = { fg = "diag_warn" },
	},
	{
		provider = function(self)
			return self.info > 0 and (diagnostics_icons[vim.diagnostic.severity.INFO] .. ":" .. self.info .. " ")
		end,
		hl = { fg = "diag_info" },
	},
	{
		provider = function(self)
			return self.hints > 0 and (diagnostics_icons[vim.diagnostic.severity.HINT] .. ":" .. self.hints)
		end,
		hl = { fg = "diag_hint" },
	},
}

return {
	LSPActive = LSPActive,
	LSPMessages = LSPMessages,
	Diagnostics = Diagnostics,
}
