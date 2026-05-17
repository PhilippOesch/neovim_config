local M = {}

---@class test_runner.JobRunner
---@field _jobs table<string, vim.SystemObj>

---Create a new job runner instance.
---@return test_runner.JobRunner
function M.new()
	return setmetatable({ _jobs = {} }, { __index = M })
end

---Run a command, cancelling any existing job with the same key.
---The on_complete callback is guaranteed to run in a vim-safe context.
---@param self test_runner.JobRunner
---@param key string
---@param cmd string[]
---@param opts table
---@param on_complete fun(obj: vim.SystemCompleted)
function M.run(self, key, cmd, opts, on_complete)
	self:cancel(key)

	local job = vim.system(cmd, opts, function(obj)
		vim.schedule(function()
			if self._jobs[key] == job then
				self._jobs[key] = nil
			end
			on_complete(obj)
		end)
	end)

	self._jobs[key] = job
end

---Cancel a running job by key.
---@param self test_runner.JobRunner
---@param key string
function M.cancel(self, key)
	local job = self._jobs[key]
	if job then
		pcall(function()
			job:kill(9)
		end)
		self._jobs[key] = nil
	end
end

---Check if a job is currently running for the given key.
---@param self test_runner.JobRunner
---@param key string
---@return boolean
function M.is_running(self, key)
	return self._jobs[key] ~= nil
end

return M
