local lsp = require("plugins.custom_sources.lsp")

local M = {}

---@alias custom_sources.builtin.source 'luasnip'

---@class custom_sources.config
---@field sources? (table|custom_sources.builtin.source)[]

local function get_default_config()
	return {
		sources = { "luasnip" },
	}
end

---@param config custom_sources.config
function M.setup(config)
	config = vim.tbl_deep_extend("force", get_default_config(), config or {})

	lsp.setup(config)
end

return M
