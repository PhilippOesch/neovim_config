local M = {}

local parser = require("plugins.jest.parser")
local formatter = require("plugins.jest.formatter")
local JestSidebar = require("plugins.jest.sidebar")

---@class JestConfig
local config = {
	patterns = { "%.test%.[tj]sx?$", "%.spec%.[tj]sx?$" },
	jest_command = "npx jest --json",
	jest_config = nil,
	icons = { pass = "✅", fail = "❌", pending = "⏳", suite = "📂" },
	sidebar_width = 45,
	results_dir = vim.fn.stdpath("cache") .. "/jest-results/",
	keybinding_run = "<leader>tef",
	keybinding_toggle = "<leader>tet",
}

---@class JestState
local state = {
	sidebar = nil,
	running_jobs = {},
}

local uv = vim.uv or vim.loop

---Check if a file matches any test pattern.
---@param filepath string
---@return boolean
local function is_test_file(filepath)
	local basename = vim.fn.fnamemodify(filepath, ":t")
	for _, pattern in ipairs(config.patterns) do
		if string.find(basename, pattern) then
			return true
		end
	end
	return false
end

---Walk up directory tree to find jest config or package.json.
---@param start_dir string
---@return {cwd: string, config_path: string|nil}|nil
local function find_jest_config(start_dir)
	local dir = start_dir
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

---Get cache file path for a test file.
---@param filepath string
---@return string
local function get_cache_path(filepath)
	local sanitized = filepath:gsub("[/\\:]", "_")
	return config.results_dir .. sanitized .. ".md"
end

---Clean up cached result files older than 7 days.
local function cleanup_old_results()
	local dir = config.results_dir
	if vim.fn.isdirectory(dir) ~= 1 then
		return
	end
	local files = vim.fn.readdir(dir)
	local now = os.time()
	local max_age = 7 * 24 * 60 * 60 -- 7 days in seconds
	for _, file in ipairs(files) do
		local path = dir .. "/" .. file
		local stat = uv.fs_stat(path)
		if stat and stat.mtime then
			local age = now - stat.mtime.sec
			if age > max_age then
				vim.fn.delete(path)
			end
		end
	end
end

---Update sidebar content based on the current buffer.
local function update_sidebar_for_current_buf()
	local filepath = vim.api.nvim_buf_get_name(0)
	local basename = vim.fn.fnamemodify(filepath, ":t")

	if not is_test_file(filepath) then
		local content = "# Test Results: "
			.. basename
			.. "\n\n## Not a test file\n\nSwitch to a test file to see results."
		state.sidebar:set_content(content)
		return
	end

	local cache_path = get_cache_path(filepath)
	if vim.fn.filereadable(cache_path) == 1 then
		local lines = vim.fn.readfile(cache_path)
		state.sidebar:set_content(table.concat(lines, "\n"))
	else
		local content = "# Test Results: "
			.. basename
			.. "\n\nNo results yet.\n\nRun tests with "
			.. config.keybinding_run
			.. "."
		state.sidebar:set_content(content)
	end
end

---Handle jest job completion.
---@param filepath string
---@param obj vim.SystemCompleted
local function handle_jest_result(filepath, obj)
	local basename = vim.fn.fnamemodify(filepath, ":t")
	local content

	if obj.code ~= 0 and (not obj.stdout or obj.stdout == "") then
		local err = obj.stderr or "Unknown error running jest"
		content = "# Test Results: " .. basename .. "\n\n## Error running tests\n\n```\n" .. err .. "\n```"
	else
		local result, parse_err = parser.parse(obj.stdout or "")
		if not result then
			content = "# Test Results: "
				.. basename
				.. "\n\n## Error parsing results\n\n```\n"
				.. (parse_err or "Unknown parse error")
				.. "\n```\n\nRaw stdout:\n```\n"
				.. (obj.stdout or "")
				.. "\n```"
		else
			content = formatter.format(basename, result, { icons = config.icons, max_console_lines = 20 })
		end
	end

	-- Save to cache
	vim.fn.mkdir(config.results_dir, "p")
	local file = io.open(get_cache_path(filepath), "w")
	if file then
		file:write(content)
		file:close()
	end

	-- Update sidebar if currently focused on this file
	if vim.api.nvim_buf_get_name(0) == filepath then
		if state.sidebar:is_open() then
			state.sidebar:set_content(content)
		end
	end
end

---Toggle the sidebar visibility.
function M.toggle_sidebar()
	if state.sidebar:is_open() then
		state.sidebar:close()
	else
		state.sidebar:open()
		update_sidebar_for_current_buf()
	end
end

---Run jest tests for the current file.
function M.run_file()
	local filepath = vim.api.nvim_buf_get_name(0)
	if not is_test_file(filepath) then
		state.sidebar:open()
		update_sidebar_for_current_buf()
		return
	end

	-- Cancel existing job for this file
	if state.running_jobs[filepath] then
		local job = state.running_jobs[filepath]
		pcall(function()
			job:kill(9)
		end)
		state.running_jobs[filepath] = nil
	end

	state.sidebar:open()
	local basename = vim.fn.fnamemodify(filepath, ":t")
	local content = "# Test Results: " .. basename .. "\n\n## Running tests..."
	state.sidebar:set_content(content)

	-- Determine jest cwd and config
	local jest_info = find_jest_config(vim.fn.fnamemodify(filepath, ":h"))
	local cwd = jest_info and jest_info.cwd or vim.fn.getcwd()
	local cmd_parts = vim.split(config.jest_command, " ")

	if jest_info and jest_info.config_path then
		table.insert(cmd_parts, "--config")
		table.insert(cmd_parts, jest_info.config_path)
	end

	table.insert(cmd_parts, filepath)

	local job = vim.system(cmd_parts, { cwd = cwd, text = true }, function(obj)
		vim.schedule(function()
			state.running_jobs[filepath] = nil
			handle_jest_result(filepath, obj)
		end)
	end)

	state.running_jobs[filepath] = job
end

---Setup the jest plugin.
---@param opts? table
function M.setup(opts)
	opts = opts or {}
	config = vim.tbl_deep_extend("force", config, opts)

	-- Ensure results dir exists
	vim.fn.mkdir(config.results_dir, "p")

	-- Cleanup old results
	cleanup_old_results()

	-- Create sidebar instance
	state.sidebar = JestSidebar.new({ width = config.sidebar_width })

	-- Keymaps
	if config.keybinding_run then
		vim.keymap.set("n", config.keybinding_run, M.run_file, {
			noremap = true,
			silent = true,
			desc = "Run jest tests for current file",
		})
	end
	if config.keybinding_toggle then
		vim.keymap.set("n", config.keybinding_toggle, M.toggle_sidebar, {
			noremap = true,
			silent = true,
			desc = "Toggle jest results sidebar",
		})
	end

	-- Autocmds
	local augroup = vim.api.nvim_create_augroup("JestSidebar", { clear = true })

	vim.api.nvim_create_autocmd("BufEnter", {
		group = augroup,
		callback = function()
			if state.sidebar:is_open() then
				-- Don't update if we're entering the sidebar buffer itself
				if vim.api.nvim_get_current_buf() == state.sidebar:get_buf() then
					return
				end
				update_sidebar_for_current_buf()
			end
		end,
	})
end

return M
