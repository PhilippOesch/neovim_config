---@class JestAdapter: test_runner.Adapter
local M = {
	patterns = { "%.test%.[tj]sx?$", "%.spec%.[tj]sx?$" },
	parser = require('plugins.test-runner.adapters.jest.parser'),
}

M.get_config = function(path)
	local dir = path
	local root = "/"
	local home = os.getenv("HOME") or ""

	while dir and dir ~= "" and dir ~= root and dir ~= home do
		local configs = {
			"jest.config.js",
			"jest.config.ts",
			"jest.config.mjs",
			"jest.config.cjs",
			"jest.config.json",
		}
		for _, name in ipairs(configs) do
			local path = dir .. "/" .. name
			if vim.fn.filereadable(path) == 1 then
				return { cwd = dir, config_path = path }
			end
		end

		if vim.fn.filereadable(dir .. "/package.json") == 1 then
			return { cwd = dir, config_path = nil }
		end

		local parent = vim.fn.fnamemodify(dir, ":h")
		if parent == dir then
			break
		end
		dir = parent
	end

	return nil
end

M.get_cwd = function(path)
	local config = M.get_config(path)

	if config and config.cwd then
		return config.cwd
	end

	return nil
end

---@param config table
---@param opts? {filepath: string}
M.get_cmd = function(config, opts)
	local cmd_parts = { "npx", "jest", "--json" }

	if config and config.config_path then
		table.insert(cmd_parts, "--config")
		table.insert(cmd_parts, config.config_path)
	end

	table.insert(cmd_parts, opts.filepath)
	return cmd_parts
end

return M
