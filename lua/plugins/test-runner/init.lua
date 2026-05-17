local M = {}

local Sidebar = require("plugins.test-runner.sidebar")
local JobRunner = require("plugins.test-runner.job_runner")
local ResultCache = require("plugins.test-runner.result_cache")

---@class ResultParser
---@field parse fun(raw: string): ParsedResult
---
---@class ResultFormatter
---@field format fun(filename: string, result: ParsedResult, opts: FormatterConfig): string

---@class Adapter
---@field patterns string[]
---@field get_cwd fun(path: string): string|nil
---@field get_cmd fun(config: table, opts:{filepath: string}): table
---@field get_config fun(path: string): table
---@field parser ResultParser
---@field formatter ResultParser

---@class JestAdapter: Adapter
local JestAdapter = require("plugins.test-runner.adapters.jest-adapter")

---@class JestConfig
local config = {
	---@type Adapter[]
	adapters = {
		require("plugins.test-runner.adapters.jest-adapter"),
	},
	icons = { pass = "✅", fail = "❌", pending = "⏳", suite = "📂" },
	sidebar_width = 45,
	results_dir = vim.fn.stdpath("cache") .. "/test-results/",
	keybinding_run = "<leader>tef",
	keybinding_toggle = "<leader>tet",
}

---@class JestState
local state = {
	sidebar = nil,
	job_runner = nil,
	result_cache = nil,
}

--- get the test adapter
---
---@param filepath string
---@return Adapter|nil
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
			.. config.keybinding_run
			.. "."
		state.sidebar:set_content(content)
	end
end

---Handle jest job completion.
---@param filepath string
---@param obj vim.SystemCompleted
---@param adapter Adapter
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
	config = vim.tbl_deep_extend("force", config, opts)

	-- Create sidebar, job runner, and result cache instances
	state.sidebar = Sidebar.new({ width = config.sidebar_width })
	state.job_runner = JobRunner.new()
	state.result_cache = ResultCache.new({ results_dir = config.results_dir })
	state.result_cache:cleanup()

	-- Keymaps
	if config.keybinding_run then
		vim.keymap.set("n", config.keybinding_run, M.run_file, {
			noremap = true,
			silent = true,
			desc = "Run tests for current file",
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
