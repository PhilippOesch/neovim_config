local M = {}

---@class DotnetTestResult
---@field testName string
---@field outcome string Passed|Failed|Skipped|NotExecuted
---@field duration string|nil ISO 8601 duration format
---@field Output table|nil Contains StdOut, ErrorInfo, etc.

---@class DotnetTestRun
---@field TestRun table Contains Results and other metadata

---Parse raw TRX JSON (converted from XML by yq) into a structured tree.
---Returns nil and an error message if parsing fails.
---@param json_string string
---@return ParsedResult|nil
---@return string|nil
function M.parse(json_string)
	if not json_string or json_string == "" then
		return nil, "Empty dotnet output"
	end

	local ok, data = pcall(vim.json.decode, json_string)
	if not ok or type(data) ~= "table" then
		return nil, "Failed to parse dotnet JSON output"
	end

	-- TRX structure: TestRun.Results.UnitTestResult (can be array or single object)
	local test_run = data.TestRun
	if not test_run then
		return nil, "No TestRun found in output"
	end

	local results = test_run.Results
	if not results then
		return nil, "No Results found in TestRun"
	end

	local test_results = results.UnitTestResult
	if not test_results then
		return nil, "No UnitTestResult found in Results"
	end

	-- Ensure test_results is an array
	if type(test_results) ~= "table" then
		return nil, "Invalid test results format"
	end

	-- Handle single result (not in array)
	if test_results.testName then
		test_results = { test_results }
	end

	local summary = {
		passed = 0,
		failed = 0,
		pending = 0,
	}

	local tree = {}

	for _, test_result in ipairs(test_results) do
		local test_name = test_result["+@testName"]
		local outcome = test_result["+@outcome"]

		if not test_name then
			goto continue
		end

		-- Update summary
		if outcome == "Passed" then
			summary.passed = summary.passed + 1
		elseif outcome == "Failed" then
			summary.failed = summary.failed + 1
		else
			-- Skipped, NotExecuted, etc.
			summary.pending = summary.pending + 1
		end

		-- Build tree from dot-separated name (e.g., "Namespace.Class.Method")
		local parts = {}
		for part in string.gmatch(test_name, "[^.]+") do
			table.insert(parts, part)
		end

		-- Navigate/create tree structure
		local current_level = tree
		for i = 1, #parts - 1 do
			local part = parts[i]
			local found = false

			for _, node in ipairs(current_level) do
				if node.name == part and node.children then
					current_level = node.children
					found = true
					break
				end
			end

			if not found then
				local new_node = {
					name = part,
					status = outcome == "Failed" and "failed" or "passed",
					children = {},
				}
				table.insert(current_level, new_node)
				current_level = new_node.children
			end
		end

		-- Create test node (leaf)
		local test_node = {
			name = parts[#parts],
			status = outcome == "Failed" and "failed" or (outcome == "Passed" and "passed" or "pending"),
		}

		-- Extract error information if failed
		if outcome == "Failed" and test_result.Output then
			local failure_messages = {}
			local error_info = test_result.Output.ErrorInfo

			if error_info then
				if error_info.Message then
					table.insert(failure_messages, error_info.Message)
				end
				if error_info.StackTrace then
					table.insert(failure_messages, error_info.StackTrace)
				end
			end

			if #failure_messages > 0 then
				test_node.failureMessages = failure_messages
			end
		end

		-- Extract console output
		if test_result.Output and test_result.Output.StdOut then
			test_node.console = {
				{ type = "log", message = test_result.Output.StdOut },
			}
		end

		-- Extract stderr if present
		if test_result.Output and test_result.Output.StdErr then
			if not test_node.console then
				test_node.console = {}
			end
			table.insert(test_node.console, { type = "error", message = test_result.Output.StdErr })
		end

		table.insert(current_level, test_node)

		::continue::
	end

	-- Bubble up status: if any child is failed, parent is failed
	local function bubble_status(nodes)
		for _, node in ipairs(nodes) do
			if node.children then
				bubble_status(node.children)
				local has_failed = false
				for _, child in ipairs(node.children) do
					if child.status == "failed" then
						has_failed = true
						break
					end
				end
				if has_failed then
					node.status = "failed"
				end
			end
		end
	end
	bubble_status(tree)

	return {
		summary = summary,
		tree = tree,
	}, nil
end

return M
