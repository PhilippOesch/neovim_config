local TestRun = {}

---@class test_runner.RunResult
---@field type "success"|"error"
---@field result? ParsedResult
---@field stage? string
---@field message? string
---@field raw? string

---@class test_runner.TestRun.new.opts
---@field job_runner test_runner.JobRunner

---@class test_runner.TestRun
---@field _job_runner test_runner.JobRunner

---Create a new TestRun instance.
---@param opts test_runner.TestRun.new.opts
---@return test_runner.TestRun
function TestRun.new(opts)
	return setmetatable({
		_job_runner = opts.job_runner,
	}, { __index = TestRun })
end

---Handle test job completion.
---@param obj vim.SystemCompleted
---@param adapter test_runner.Adapter
---@param context table|nil
---@return test_runner.RunResult
function TestRun:_handle_result(obj, adapter, context)
	local stdout = obj.stdout
	local proc_err

	if adapter.post_process then
		stdout, proc_err = adapter.post_process(obj, context)
	end

	if not stdout then
		return {
			type = "error",
			stage = "post_process",
			message = proc_err or "Unknown error processing results",
		}
	end

	if obj.code ~= 0 and (stdout == "" or stdout == nil) then
		return {
			type = "error",
			stage = "run",
			message = obj.stderr or "Unknown error running tests",
		}
	end

	local result, parse_err = adapter.parser.parse(stdout or "")
	if not result then
		return {
			type = "error",
			stage = "parse",
			message = parse_err or "Unknown parse error",
			raw = stdout or "",
		}
	end

	return {
		type = "success",
		result = result,
	}
end

---Run tests for a file.
---@param adapter test_runner.Adapter
---@param filepath string
---@param on_complete fun(run_result: test_runner.RunResult)
function TestRun:run(adapter, filepath, on_complete)
	local dir = vim.fn.fnamemodify(filepath, ":h")

	local adapter_config = adapter.get_config(dir)
	if not adapter_config then
		on_complete({
			type = "error",
			stage = "config",
			message = "Could not find test configuration (e.g., solution file)",
		})
		return
	end

	local cwd = adapter.get_cwd(dir) or vim.fn.getcwd()

	local context
	if adapter.get_context then
		context = adapter.get_context(adapter_config, { filepath = filepath })
		if not context then
			on_complete({
				type = "error",
				stage = "context",
				message = "Failed to prepare test context",
			})
			return
		end
	end

	local cmd_parts = adapter.get_cmd(adapter_config, { filepath = filepath }, context)
	if not cmd_parts then
		on_complete({
			type = "error",
			stage = "cmd",
			message = "Failed to build test command",
		})
		return
	end

	self._job_runner:run(filepath, cmd_parts, { cwd = cwd, text = true }, function(obj)
		local run_result = self:_handle_result(obj, adapter, context)
		on_complete(run_result)
	end)
end

return TestRun
