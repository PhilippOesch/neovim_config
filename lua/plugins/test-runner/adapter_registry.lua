local AdapterRegistry = {}

local built_in = require("plugins.test-runner.adapters")

---@class test_runner.AdapterRegistry
---@field new fun(specs: (string|test_runner.Adapter)[]): test_runner.AdapterRegistry
---@field find fun(self: test_runner.AdapterRegistry, filepath: string): test_runner.Adapter|nil
---@field list fun(self: test_runner.AdapterRegistry): test_runner.Adapter[]

---Create a new AdapterRegistry instance from specs.
---String names are resolved against the built-in adapter index.
---Table values are accepted as inline adapters.
---@param specs (string|test_runner.Adapter)[]
---@return test_runner.AdapterRegistry
function AdapterRegistry.new(specs)
	local adapters = {}
	for _, spec in ipairs(specs) do
		if type(spec) == "string" then
			local path = built_in[spec]
			if not path then
				error("Unknown built-in adapter: " .. spec)
			end
			table.insert(adapters, require(path))
		elseif type(spec) == "table" then
			table.insert(adapters, spec)
		end
	end
	return setmetatable({ _adapters = adapters }, { __index = AdapterRegistry })
end

---Find the first adapter whose patterns match the file basename.
---@param filepath string
---@return test_runner.Adapter|nil
function AdapterRegistry:find(filepath)
	local basename = vim.fn.fnamemodify(filepath, ":t")
	for _, adapter in ipairs(self._adapters) do
		for _, pattern in ipairs(adapter.patterns) do
			if string.find(basename, pattern) then
				return adapter
			end
		end
	end
	return nil
end

---Return the list of resolved adapters.
---@return test_runner.Adapter[]
function AdapterRegistry:list()
	return self._adapters
end

return AdapterRegistry
