local M = {}

---@class FormatterConfig
---@field icons {pass: string, fail: string, pending: string, suite: string}
---@field max_console_lines number|nil

---@class ParsedTestNode
---@field name string
---@field status string
---@field children ParsedTestNode[]|nil
---@field failureMessages string[]|nil
---@field console {message: string, type: string}[]|nil

---@class ParsedResult
---@field summary {passed: number, failed: number, pending: number}
---@field tree ParsedTestNode[]

---@class test_runner.RunResult
---@field type "success"|"error"
---@field result? ParsedResult
---@field stage? string
---@field message? string
---@field raw? string

local STAGE_MESSAGES = {
	config = "Could not find test configuration",
	context = "Failed to prepare test context",
	cmd = "Failed to build test command",
	post_process = "Error processing results",
	run = "Error running tests",
	parse = "Error parsing results",
}

---Render a run result as markdown.
---@param filename string basename of the test file
---@param run_result test_runner.RunResult
---@param opts FormatterConfig
---@return string
function M.render(filename, run_result, opts)
	local lines = {}

	table.insert(lines, "# Test Results: " .. filename)
	table.insert(lines, "")

	if run_result.type == "success" then
		if not run_result.result then
			table.insert(lines, "## Running tests...")
			return table.concat(lines, "\n")
		end
		return M.format(filename, run_result.result, opts)
	end

	local msg = STAGE_MESSAGES[run_result.stage] or "Unknown error"
	table.insert(lines, "## Error: " .. msg)
	table.insert(lines, "")

	if run_result.message and run_result.message ~= "" then
		table.insert(lines, "```")
		table.insert(lines, run_result.message)
		table.insert(lines, "```")
	end

	if run_result.raw and run_result.raw ~= "" then
		table.insert(lines, "")
		table.insert(lines, "Raw output:")
		table.insert(lines, "```")
		for _, raw_line in ipairs(vim.split(run_result.raw, "\n")) do
			table.insert(lines, raw_line)
		end
		table.insert(lines, "```")
	end

	return table.concat(lines, "\n")
end

---Format parsed jest result as markdown string.
---@param filename string basename of the test file
---@param result ParsedResult|nil
---@param opts FormatterConfig
---@return string
function M.format(filename, result, opts)
	local lines = {}
	local icons = opts.icons
	local max_lines = opts.max_console_lines or 20

	table.insert(lines, "# Test Results: " .. filename)
	table.insert(lines, "")

	if not result then
		table.insert(lines, "## Running tests...")
		return table.concat(lines, "\n")
	end

	table.insert(
		lines,
		string.format("**%d passed, %d failed, %d skipped**", result.summary.passed, result.summary.failed, result.summary.pending)
	)
	table.insert(lines, "")

	if #result.tree == 0 then
		table.insert(lines, "_No tests found._")
		return table.concat(lines, "\n")
	end

	---Collect output lines for a failed test, truncating to max_lines.
	---@param node ParsedTestNode
	---@param indent number
	---@return string[]
	local function collect_output_lines(node, indent)
		local out = {}
		local prefix = string.rep("  ", indent + 1)

		if node.failureMessages then
			for _, msg in ipairs(node.failureMessages) do
				for _, msg_line in ipairs(vim.split(msg, "\n")) do
					table.insert(out, prefix .. msg_line)
				end
			end
		end

		if node.console and #node.console > 0 then
			if node.failureMessages and #node.failureMessages > 0 then
				table.insert(out, prefix .. "---")
			end
			for _, entry in ipairs(node.console) do
				for _, c_line in ipairs(vim.split(entry.message, "\n")) do
					table.insert(out, prefix .. "[" .. entry.type .. "] " .. c_line)
				end
			end
		end

		if #out > max_lines then
			local truncated = {}
			for i = 1, max_lines do
				table.insert(truncated, out[i])
			end
			table.insert(truncated, prefix .. "... (" .. (#out - max_lines) .. " more lines)")
			return truncated
		end

		return out
	end

	local function format_node(node, indent)
		local icon = icons.pass
		if node.status == "failed" then
			icon = icons.fail
		elseif node.status == "pending" or node.status == "skipped" or node.status == "todo" then
			icon = icons.pending
		end

		local is_suite = node.children ~= nil
		local suite_icon = is_suite and (icons.suite .. " ") or ""

		local line = string.rep("  ", indent) .. "- " .. suite_icon .. icon .. " " .. node.name
		table.insert(lines, line)

		if node.children then
			for _, child in ipairs(node.children) do
				format_node(child, indent + 1)
			end
		end

		-- Show failure messages and console output for failed tests
		if node.status == "failed" then
			local output = collect_output_lines(node, indent)
			if #output > 0 then
				local prefix = string.rep("  ", indent + 1)
				table.insert(lines, prefix .. "<!-- {{{1 -->")
				table.insert(lines, prefix .. "```")
				for _, out_line in ipairs(output) do
					table.insert(lines, out_line)
				end
				table.insert(lines, prefix .. "```")
				table.insert(lines, prefix .. "<!-- }}}1 -->")
			end
		end
	end

	for _, node in ipairs(result.tree) do
		format_node(node, 0)
	end

	return table.concat(lines, "\n")
end

return M
