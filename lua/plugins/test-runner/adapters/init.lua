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
---@field get_cmd fun(config: table, opts:{filepath: string}, context?: table): table|nil
---@field get_config fun(path: string): table
---@field get_context fun(config: table, opts:{filepath: string}): table|nil Optional: generate context for test run
---@field post_process fun(obj: vim.SystemCompleted, context: table): string|nil, string|nil Optional: process output before parsing
---@field parser ResultParser
---@field formatter ResultFormatter
---
---@type table<string, test_runner.Adapter>
local M = {
	jest = require("plugins.test-runner.adapters.jest.adapter"),
	dotnet = require("plugins.test-runner.adapters.dotnet.adapter"),
	mini = require("plugins.test-runner.adapters.mini.adapter"),
}

return M
