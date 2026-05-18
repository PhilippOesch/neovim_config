local M = {}

local Sidebar = require("plugins.test-runner.sidebar")
local JobRunner = require("plugins.test-runner.job_runner")
local ResultCache = require("plugins.test-runner.result_cache")

local adapters = require("plugins.test-runner.adapters")

--- available keybindings
---@class test_runner.config.keybindings
---@field run? string
---@field toggle? string

--- The plugin configuration.
---@class test_runner.config
---@field adapters test_runner.Adapter[]
---@field icons table
---@field sidebar_width integer
---@field results_dir string
---@field keybindings test_runner.config.keybindings

--- Returns the default config for this plugin
---
---@return test_runner.config
local get_default_config = function()
	return {
		adapters = {
			adapters.jest,
			adapters.dotnet,
		},
		icons = { pass = "✅", fail = "❌", pending = "⏳", suite = "📂" },
		sidebar_width = 45,
		results_dir = vim.fn.stdpath("cache") .. "/test-results/",
		keybindings = {
			run = "<leader>tef",
			toggle = "<leader>tet",
		},
	}
end

---@type test_runner.config
local config = {}

---@class test_runner.State
---@field sidebar test_runner.Sidebar|nil
---@field job_runner test_runner.JobRunner|nil
---@field result_cache test_runner.ResultCache|nil
local state = {
	sidebar = nil,
	job_runner = nil,
	result_cache = nil,
}

--- get the test adapter
---
---@param filepath string
---@return test_runner.Adapter|nil
local function get_test_adapter(filepath)
	local basename = vim.fn.fnamemodify(filepath, ":t")

	for _, adapter in ipairs(config.adapters) do
		for _, pattern in ipairs(adapter.patterns) do
			if string.find(basename, pattern) then
				return adapter
			end
		end
	end

	return nil
end

---Update sidebar content based on the current buffer.
local function update_sidebar_for_current_buf()
	local filepath = vim.api.nvim_buf_get_name(0)
	local basename = vim.fn.fnamemodify(filepath, ":t")

	if not get_test_adapter(filepath) then
		local content = "# Test Results: "
			.. basename
			.. "\n\n## Not a test file\n\nSwitch to a test file to see results."
		state.sidebar:set_content(content)
		return
	end

	local cached = state.result_cache:load(filepath)
	if cached then
		state.sidebar:set_content(cached)
	else
		local content = "# Test Results: "
			.. basename
			.. "\n\nNo results yet.\n\nRun tests with "
			.. config.keybindings.run
			.. "."
		state.sidebar:set_content(content)
	end
end

---Handle jest job completion.
---@param filepath string
---@param obj vim.SystemCompleted
---@param adapter test_runner.Adapter
local function handle_result(filepath, obj, adapter)
	local basename = vim.fn.fnamemodify(filepath, ":t")
	local content

	if obj.code ~= 0 and (not obj.stdout or obj.stdout == "") then
		local err = obj.stderr or "Unknown error running jest"
		content = "# Test Results: " .. basename .. "\n\n## Error running tests\n\n```\n" .. err .. "\n```"
	else
		local result, parse_err = adapter.parser.parse(obj.stdout or "")
		if not result then
			content = "# Test Results: "
				.. basename
				.. "\n\n## Error parsing results\n\n```\n"
				.. (parse_err or "Unknown parse error")
				.. "\n```\n\nRaw stdout:\n```\n"
				.. (obj.stdout or "")
				.. "\n```"
		else
			content = adapter.formatter.format(basename, result, { icons = config.icons, max_console_lines = 20 })
		end
	end

	-- Save to cache
	state.result_cache:save(filepath, content)

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

	local adapter = get_test_adapter(filepath)

	if not adapter then
		state.sidebar:open()
		update_sidebar_for_current_buf()
		return
	end

	state.sidebar:open()
	local basename = vim.fn.fnamemodify(filepath, ":t")
	local content = "# Test Results: " .. basename .. "\n\n## Running tests..."
	state.sidebar:set_content(content)

	local adapter_config = adapter.get_config(vim.fn.fnamemodify(filepath, ":h"))
	local cwd = adapter.get_cwd(vim.fn.fnamemodify(filepath, ":h")) or vim.fn.getcwd()
	local cmd_parts = adapter.get_cmd(adapter_config, { filepath = filepath })

	state.job_runner:run(filepath, cmd_parts, { cwd = cwd, text = true }, function(obj)
		handle_result(filepath, obj, adapter)
	end)
end

---Setup the jest plugin.
---@param opts? table
function M.setup(opts)
	opts = opts or {}
	config = vim.tbl_deep_extend("force", get_default_config(), opts)

	-- Create sidebar, job runner, and result cache instances
	state.sidebar = Sidebar.new({ width = config.sidebar_width })
	state.job_runner = JobRunner.new()
	state.result_cache = ResultCache.new({ results_dir = config.results_dir })
	state.result_cache:cleanup()

	-- Keymaps
	if config.keybindings.run then
		vim.keymap.set("n", config.keybindings.run, M.run_file, {
			noremap = true,
			silent = true,
			desc = "Run tests for current file",
		})
	end
	if config.keybindings.toggle then
		vim.keymap.set("n", config.keybindings.toggle, M.toggle_sidebar, {
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
