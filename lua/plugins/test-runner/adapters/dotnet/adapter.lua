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
		local csproj_files = vim.fn.glob(dir .. "/*.csproj", false, true)
		for _, file in ipairs(csproj_files) do
			local basename = vim.fn.fnamemodify(file, ":t:r")
			if basename:match("^[Tt]ests?") or basename:match("[Tt]ests?$") then
				return { cwd = dir, solutionFile = file }
			end
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
	return config and config.cwd or nil
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

	local filter, err = M.parser.extract_filter(bufnr)
	if not filter then
		local level = err == "no classes found" and vim.log.levels.WARN or vim.log.levels.ERROR
		vim.notify("Dotnet adapter: " .. err .. " in " .. opts.filepath, level)
		return nil
	end

	local cmd = {
		"dotnet",
		"test",
		config.solutionFile,
		"--filter",
		filter,
	}

	if context and context.results_dir then
		vim.list_extend(cmd, {
			"--results-directory",
			context.results_dir,
			"--logger",
			"trx",
		})
	end

	return cmd
end

---Find the TRX file in the results directory
---@param results_dir string
---@return string|nil
local function find_trx_file(results_dir)
	for _, pattern in ipairs({ results_dir .. "/TestResults/*.trx", results_dir .. "/*.trx" }) do
		local trx_files = vim.fn.glob(pattern, false, true)
		if #trx_files > 0 then
			return trx_files[1]
		end
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
