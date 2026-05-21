---@class DotnetTestAdapter: test_runner.Adapter
local M = {
	patterns = { ".[Tt]est%.cs$" },
	parser = require("plugins.test-runner.adapters.dotnet.parser"),
}

-- Cache yq availability check
local _yq_checked = false
local _yq_available = false

local function check_yq()
	if _yq_checked then
		return _yq_available
	end
	_yq_available = vim.fn.executable("yq") == 1
	_yq_checked = true
	if not _yq_available then
		vim.notify("Dotnet adapter requires 'yq' (v4+) for XML parsing. Install: brew install yq", vim.log.levels.ERROR)
	end
	return _yq_available
end

M.get_config = function(path)
	local dir = path
	local root = "/"
	local home = os.getenv("HOME") or ""

	while dir and dir ~= "" and dir ~= root and dir ~= home do
		local has_git_dir = vim.fn.finddir(".git", dir .. "/") ~= ""
		local has_git_file = vim.fn.filereadable(dir .. "/.git") == 1
		if has_git_dir or has_git_file then
			local solutions = vim.fn.glob(dir .. "/*.sln", false, true)
			local solutionFile = solutions[1]
			if not solutionFile or solutionFile == "" then
				solutionFile = dir .. "/dirs.proj"
			end
			return { cwd = dir, solutionFile = solutionFile }
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

---Generate context for test run including temp directory for TRX
---@param config table
---@param opts {filepath: string}
---@return table|nil
M.get_context = function(config, opts)
	if not check_yq() then
		return nil
	end

	-- Create a temp directory for test results
	local temp_dir = vim.fn.tempname()
	vim.fn.mkdir(temp_dir, "p")

	return {
		results_dir = temp_dir,
		filepath = opts.filepath,
	}
end

---@param config table
---@param opts {filepath: string}
---@param context table|nil
M.get_cmd = function(config, opts, context)
	local bufnr = vim.fn.bufnr(opts.filepath)
	if bufnr == -1 then
		vim.notify("Dotnet adapter: buffer not found for " .. opts.filepath, vim.log.levels.ERROR)
		return nil
	end

	local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "c_sharp")
	if not ok or not parser then
		vim.notify("Dotnet adapter: c_sharp treesitter parser not available", vim.log.levels.ERROR)
		return nil
	end

	local tree = parser:parse()[1]
	local root = tree:root()

	-- Query for namespace declarations (both file-scoped and block-style)
	local namespace_query = vim.treesitter.query.parse(
		"c_sharp",
		[[
		(file_scoped_namespace_declaration name: (_) @namespace.name)
		(namespace_declaration name: (_) @namespace.name)
	]]
	)

	local namespaces = {}
	for _, node in namespace_query:iter_captures(root, bufnr) do
		local name = vim.treesitter.get_node_text(node, bufnr)
		table.insert(namespaces, name)
	end

	-- Query for class declarations
	local class_query = vim.treesitter.query.parse(
		"c_sharp",
		[[
		(class_declaration name: (identifier) @class.name)
	]]
	)

	local class_names = {}
	for _, node in class_query:iter_captures(root, bufnr) do
		local name = vim.treesitter.get_node_text(node, bufnr)
		table.insert(class_names, name)
	end

	if #class_names == 0 then
		vim.notify("Dotnet adapter: no classes found in " .. opts.filepath, vim.log.levels.WARN)
		return nil
	end

	-- Build filter with namespace prefix for fully qualified names
	local filter_parts = {}
	local namespace_prefix = namespaces[1] and (namespaces[1] .. ".") or ""

	for _, name in ipairs(class_names) do
		table.insert(filter_parts, string.format("FullyQualifiedName~%s%s", namespace_prefix, name))
	end

	local filter = table.concat(filter_parts, "|")

	local cmd = {
		"dotnet",
		"test",
		config.solutionFile,
		"--filter",
		filter,
	}

	-- Add TRX logger with results directory if context provided
	if context and context.results_dir then
		table.insert(cmd, "--results-directory")
		table.insert(cmd, context.results_dir)
		table.insert(cmd, "--logger")
		table.insert(cmd, "trx")
	end

	return cmd
end

---Find the TRX file in the results directory
---@param results_dir string
---@return string|nil
local function find_trx_file(results_dir)
	-- TRX files are typically in results_dir/TestResults/*.trx
	local test_results_dir = results_dir .. "/TestResults"

	-- Check if TestResults subdirectory exists
	if vim.fn.isdirectory(test_results_dir) == 1 then
		local trx_files = vim.fn.glob(test_results_dir .. "/*.trx", false, true)
		if #trx_files > 0 then
			return trx_files[1]
		end
	end

	-- Try direct search in results_dir
	local trx_files = vim.fn.glob(results_dir .. "/*.trx", false, true)
	if #trx_files > 0 then
		return trx_files[1]
	end

	return nil
end

---Post-process TRX output to JSON
---@param obj vim.SystemCompleted
---@param context table
---@return string|nil, string|nil
M.post_process = function(obj, context)
	if not context or not context.results_dir then
		return nil, "No results directory in context"
	end

	-- Find the TRX file
	local trx_path = find_trx_file(context.results_dir)

	if not trx_path then
		local err_msg = "TRX file not found in " .. context.results_dir
		if obj.stderr and obj.stderr ~= "" then
			err_msg = err_msg .. "\nStderr: " .. obj.stderr
		end
		-- Cleanup temp directory
		vim.fn.delete(context.results_dir, "rf")
		return nil, err_msg
	end

	-- Convert TRX to JSON using yq
	local cmd = { "yq", "-p", "xml", "-o", "json", trx_path }
	local result = vim.system(cmd, { text = true }):wait()

	-- Cleanup temp directory
	vim.fn.delete(context.results_dir, "rf")

	if result.code ~= 0 then
		return nil, "yq conversion failed: " .. (result.stderr or "unknown error")
	end

	if not result.stdout or result.stdout == "" then
		return nil, "yq produced empty output"
	end

	return result.stdout, nil
end

return M
