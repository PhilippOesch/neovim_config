local TestRun = {}

---@class test_runner.TestRun.new.opts
---@field job_runner test_runner.JobRunner
---@field icons? table
---@field max_console_lines? number

---@class test_runner.TestRun
---@field _job_runner test_runner.JobRunner
---@field _icons table
---@field _max_console_lines number

---Create a new TestRun instance.
---@param opts test_runner.TestRun.new.opts
---@return test_runner.TestRun
function TestRun.new(opts)
	return setmetatable({
		_job_runner = opts.job_runner,
		_icons = opts.icons or { pass = "✅", fail = "❌", pending = "⏳", suite = "📂" },
		_max_console_lines = opts.max_console_lines or 20,
	}, { __index = TestRun })
end

---Handle test job completion.
---@param basename string
---@param obj vim.SystemCompleted
---@param adapter test_runner.Adapter
---@param context table|nil
---@return string
function TestRun:_handle_result(basename, obj, adapter, context)
	local content
	local stdout = obj.stdout
	local proc_err

	if adapter.post_process then
		stdout, proc_err = adapter.post_process(obj, context)
	end

	if not stdout then
		local err = proc_err or "Unknown error processing results"
		content = "# Test Results: " .. basename .. "\n\n## Error processing results\n\n```\n" .. err .. "\n```"
	elseif obj.code ~= 0 and (stdout == "" or stdout == nil) then
		local err = obj.stderr or "Unknown error running tests"
		content = "# Test Results: " .. basename .. "\n\n## Error running tests\n\n```\n" .. err .. "\n```"
	else
		local result, parse_err = adapter.parser.parse(stdout or "")
		if not result then
			content = "# Test Results: "
				.. basename
				.. "\n\n## Error parsing results\n\n```\n"
				.. (parse_err or "Unknown parse error")
				.. "\n```\n\nRaw stdout:\n```\n"
				.. (stdout or "")
				.. "\n```"
		else
			content = adapter.formatter.format(basename, result, { icons = self._icons, max_console_lines = self._max_console_lines })
		end
	end

	return content
end

---Run tests for a file.
---@param adapter test_runner.Adapter
---@param filepath string
---@param on_complete fun(content: string)
function TestRun:run(adapter, filepath, on_complete)
	local basename = vim.fn.fnamemodify(filepath, ":t")
	local dir = vim.fn.fnamemodify(filepath, ":h")

	local adapter_config = adapter.get_config(dir)
	if not adapter_config then
		on_complete("# Test Results: " .. basename .. "\n\n## Error: Could not find test configuration (e.g., solution file)")
		return
	end

	local cwd = adapter.get_cwd(dir) or vim.fn.getcwd()

	local context
	if adapter.get_context then
		context = adapter.get_context(adapter_config, { filepath = filepath })
		if not context then
			on_complete("# Test Results: " .. basename .. "\n\n## Error: Failed to prepare test context")
			return
		end
	end

	local cmd_parts = adapter.get_cmd(adapter_config, { filepath = filepath }, context)
	if not cmd_parts then
		on_complete("# Test Results: " .. basename .. "\n\n## Error: Failed to build test command")
		return
	end

	self._job_runner:run(filepath, cmd_parts, { cwd = cwd, text = true }, function(obj)
		local content = self:_handle_result(basename, obj, adapter, context)
		on_complete(content)
	end)
end

return TestRun
