local M = {}

---@class test_runner.ResultCache
---@field _results_dir string
---@field _max_age_seconds number
---@field load fun(self: test_runner.ResultCache, filepath: string): string|nil
---@field save fun(self: test_runner.ResultCache, filepath: string, content: string)
---@field cleanup fun(self: test_runner.ResultCache)

---Create a new result cache instance.
---@param opts { results_dir: string, max_age_seconds?: number }
---@return test_runner.ResultCache
function M.new(opts)
	return setmetatable({
		_results_dir = opts.results_dir,
		_max_age_seconds = opts.max_age_seconds or 7 * 24 * 60 * 60,
	}, { __index = M })
end

---Get cache file path for a test file.
---@param self test_runner.ResultCache
---@param filepath string
---@return string
local function get_cache_path(self, filepath)
	local sanitized = filepath:gsub("[/\\:]", "_")
	return self._results_dir .. sanitized .. ".md"
end

---Load cached content for a test file.
---@param filepath string
---@return string|nil
function M:load(self, filepath)
	local cache_path = get_cache_path(self, filepath)
	if vim.fn.filereadable(cache_path) == 1 then
		local lines = vim.fn.readfile(cache_path)
		return table.concat(lines, "\n")
	end
	return nil
end

---Save content to cache for a test file.
---@param filepath string
---@param content string
function M:save(self, filepath, content)
	vim.fn.mkdir(self._results_dir, "p")
	local file = io.open(get_cache_path(self, filepath), "w")
	if file then
		file:write(content)
		file:close()
	end
end

---Clean up cached result files older than max_age_seconds.
function M:cleanup(self)
	local uv = vim.uv or vim.loop
	if vim.fn.isdirectory(self._results_dir) ~= 1 then
		return
	end
	local files = vim.fn.readdir(self._results_dir)
	local now = os.time()
	for _, file in ipairs(files) do
		local path = self._results_dir .. "/" .. file
		local stat = uv.fs_stat(path)
		if stat and stat.mtime then
			local age = now - stat.mtime.sec
			if age > self._max_age_seconds then
				vim.fn.delete(path)
			end
		end
	end
end

return M
