---@class DotnetTestAdapter: test_runner.Adapter
local M = {
	patterns = { ".[Tt]est%.cs$" },
	formatter = require("plugins.test-runner.formatter"),
	parser = require("plugins.test-runner.adapters.dotnet.parser"),
}

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

---@param config table
---@param opts? {filepath: string}
M.get_cmd = function(config, opts)
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

	vim.print(filter_parts)

	local cmd = { "dotnet", "test", config.solutionFile, "--filter", filter }

	return cmd
end

return M
