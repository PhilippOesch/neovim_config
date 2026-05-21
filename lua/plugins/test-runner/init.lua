local M = {}

local Sidebar = require("plugins.test-runner.sidebar")
local JobRunner = require("plugins.test-runner.job_runner")
local ResultCache = require("plugins.test-runner.result_cache")
local TestRun = require("plugins.test-runner.test_run")

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
			adapters.mini,
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
---@field test_run test_runner.TestRun|nil
local state = {
	sidebar = nil,
	job_runner = nil,
	result_cache = nil,
	test_run = nil,
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

---Toggle the sidebar visibility.
function M.toggle_sidebar()
	if state.sidebar:is_open() then
		state.sidebar:close()
	else
		state.sidebar:open()
		update_sidebar_for_current_buf()
	end
end

---Run tests for the current file.
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
	state.sidebar:set_content("# Test Results: " .. basename .. "\n\n## Running tests...")

	state.test_run:run(adapter, filepath, function(content)
		state.result_cache:save(filepath, content)
		if vim.api.nvim_buf_get_name(0) == filepath then
			if state.sidebar:is_open() then
				state.sidebar:set_content(content)
			end
		end
	end)
end

---Setup the test runner plugin.
---@param opts? table
function M.setup(opts)
	opts = opts or {}
	config = vim.tbl_deep_extend("force", get_default_config(), opts)

	-- Create sidebar, job runner, result cache, and test run instances
	state.sidebar = Sidebar.new({ width = config.sidebar_width })
	state.job_runner = JobRunner.new()
	state.result_cache = ResultCache.new({ results_dir = config.results_dir })
	state.test_run = TestRun.new({ job_runner = state.job_runner, icons = config.icons, max_console_lines = 20 })
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
			desc = "Toggle test results sidebar",
		})
	end

	-- Autocmds
	local augroup = vim.api.nvim_create_augroup("TestRunnerSidebar", { clear = true })

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
