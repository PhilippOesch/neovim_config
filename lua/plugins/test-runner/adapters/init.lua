---@class ResultParser
---@field parse fun(raw: string): ParsedResult

---@class ResultFormatter
---@field format fun(filename: string, result: ParsedResult, opts: FormatterConfig): string

--- Generic Adapter interface
---
--- Implement this to create adapter for different testing framework.
---@class test_runner.Adapter
---@field patterns string[]
---@field get_cwd fun(path: string): string|nil
---@field get_cmd fun(config: table, opts:{filepath: string}): table
---@field get_config fun(path: string): table
---@field parser ResultParser
---@field formatter ResultParser
---
---@type table<string, test_runner.Adapter>
local M = {
	jest = require("plugins.test-runner.adapters.jest.adapter"),
}

return M
