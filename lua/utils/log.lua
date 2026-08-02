local Log = {}

local config = {
	log_level = vim.log.levels.WARN,
	log_file = vim.fn.stdpath("log") .. "/nvim_config.log",
}

local level_names = {
	[vim.log.levels.TRACE] = "TRACE",
	[vim.log.levels.DEBUG] = "DEBUG",
	[vim.log.levels.INFO] = "INFO",
	[vim.log.levels.WARN] = "WARN",
	[vim.log.levels.ERROR] = "ERROR",
	[vim.log.levels.OFF] = "OFF",
}

local _write_error_notified = false

local function get_level_name(level)
	return level_names[level] or "UNKNOWN"
end

local function format_message(level, msg, info)
	local source = info and info.short_src or "unknown"
	local line = info and info.currentline or 0

	if type(msg) ~= "string" then
		msg = vim.inspect(msg)
	end

	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	local level_name = get_level_name(level)

	return string.format("%-5s  %s  %s:%d  %s", level_name, timestamp, source, line, msg)
end

local function write_to_file(msg)
	local ok, err = pcall(function()
		local dir = vim.fn.fnamemodify(config.log_file, ":h")
		vim.fn.mkdir(dir, "p")

		local file = io.open(config.log_file, "a")
		if not file then
			error("Failed to open log file: " .. config.log_file)
		end
		file:write(msg .. "\n")
		file:close()
	end)

	if not ok and not _write_error_notified then
		_write_error_notified = true
		vim.notify("testreport: failed to write to log file: " .. tostring(err), vim.log.levels.ERROR)
	end
end

---Configure the logger. Called automatically by the plugin's setup().
---@param opts? { log_level?: integer, log_file?: string }
function Log.setup(opts)
	config = vim.tbl_extend("force", config, opts or {})
	vim.api.nvim_create_user_command("TestReportLog", "tabe " .. config.log_file, { desc = "Open TestReport log file" })
end

---Check if a given log level is enabled under the current configuration.
---@param level integer A vim.log.levels value.
---@return boolean
function Log.is_enabled_for(level)
	return config.log_level ~= vim.log.levels.OFF and level >= config.log_level
end

---Write a log message at the specified level.
---@param level integer A vim.log.levels value.
---@param msg any Message to log. Non-strings are vim.inspect'd.
function Log.log(level, msg)
	if not Log.is_enabled_for(level) then
		return
	end

	-- Walk up the stack to find the first frame outside this module.
	local info
	for i = 3, 5 do
		info = debug.getinfo(i, "Sl")
		if not info or not info.short_src or not info.short_src:match("testreport/log%.lua$") then
			break
		end
	end

	local formatted = format_message(level, msg, info)
	write_to_file(formatted)
end

---@param msg any
function Log.trace(msg)
	Log.log(vim.log.levels.TRACE, msg)
end

---@param msg any
function Log.debug(msg)
	Log.log(vim.log.levels.DEBUG, msg)
end

---@param msg any
function Log.info(msg)
	Log.log(vim.log.levels.INFO, msg)
end

---@param msg any
function Log.warn(msg)
	Log.log(vim.log.levels.WARN, msg)
end

---@param msg any
function Log.error(msg)
	Log.log(vim.log.levels.ERROR, msg)
end

return Log
