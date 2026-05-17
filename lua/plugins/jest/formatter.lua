local M = {}

---@class FormatterConfig
---@field icons {pass: string, fail: string, pending: string}

---@class ParsedTestNode
---@field name string
---@field status string
---@field children table[]|nil
---@field failureMessages string[]|nil
---@field console {message: string, type: string}[]|nil

---@class ParsedResult
---@field summary {passed: number, failed: number, pending: number}
---@field tree ParsedTestNode[]

---Format parsed jest result as markdown string.
---@param filename string basename of the test file
---@param result ParsedResult|nil
---@param opts FormatterConfig
---@return string
function M.format(filename, result, opts)
	local lines = {}
	local icons = opts.icons

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

	local function format_node(node, indent)
		local icon = icons.pass
		if node.status == "failed" then
			icon = icons.fail
		elseif node.status == "pending" or node.status == "skipped" or node.status == "todo" then
			icon = icons.pending
		end

		local line = string.rep("  ", indent) .. "- " .. icon .. " " .. node.name
		table.insert(lines, line)

		if node.children then
			for _, child in ipairs(node.children) do
				format_node(child, indent + 1)
			end
		end

		-- Show failure messages and console output for failed tests
		if node.status == "failed" then
			local has_output = (node.failureMessages and #node.failureMessages > 0)
				or (node.console and #node.console > 0)
			if has_output then
				table.insert(lines, string.rep("  ", indent + 1) .. "```")
				if node.failureMessages then
					for _, msg in ipairs(node.failureMessages) do
						for _, msg_line in ipairs(vim.split(msg, "\n")) do
							table.insert(lines, string.rep("  ", indent + 1) .. msg_line)
						end
					end
				end
				if node.console and #node.console > 0 then
					if node.failureMessages and #node.failureMessages > 0 then
						table.insert(lines, string.rep("  ", indent + 1) .. "---")
					end
					for _, entry in ipairs(node.console) do
						for _, c_line in ipairs(vim.split(entry.message, "\n")) do
							table.insert(lines, string.rep("  ", indent + 1) .. "[" .. entry.type .. "] " .. c_line)
						end
					end
				end
				table.insert(lines, string.rep("  ", indent + 1) .. "```")
			end
		end
	end

	for _, node in ipairs(result.tree) do
		format_node(node, 0)
	end

	return table.concat(lines, "\n")
end

return M
