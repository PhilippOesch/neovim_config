local lsp = require("plugins.custom_sources.lsp")
local builtins = require("plugins.custom_sources.sources")

local M = {}

---@alias custom_sources.builtin.source 'luasnip'

---@class custom_sources.config
---@field sources? (table|custom_sources.builtin.source)[]
---@field trigger_chars? string[]

local function build_trigger_chars()
	local chars = {}
	for i = string.byte("a"), string.byte("z") do
		table.insert(chars, string.char(i))
	end
	for i = string.byte("A"), string.byte("Z") do
		table.insert(chars, string.char(i))
	end
	table.insert(chars, "_")
	return chars
end

local function get_default_config()
	return {
		sources = { "luasnip", "dadbod" },
		trigger_chars = build_trigger_chars(),
	}
end

---@param config custom_sources.config
function M.setup(config)
	config = vim.tbl_deep_extend("force", get_default_config(), config or {})

	local active_sources = {}
	local seen_names = {}

	for _, spec in ipairs(config.sources) do
		local source
		if type(spec) == "string" then
			source = builtins[spec]
			assert(source, "Unknown built-in source: " .. spec)
		else
			source = spec
		end

		assert(source.name, "Source must have a 'name' field")
		assert(source.get_completions, "Source must have a 'get_completions' function")
		assert(not seen_names[source.name], "Duplicate source name: " .. source.name)

		seen_names[source.name] = true
		table.insert(active_sources, source)
	end

	local server_def = lsp.create_server_def(active_sources, config.trigger_chars)
	vim.lsp.config["custom_source_ls"] = {
		cmd = require("plugins.custom_sources.utils").create_lsp(server_def),
		root_dir = function(_, on_dir)
			on_dir(vim.fn.getcwd())
		end,
	}
end

return M
