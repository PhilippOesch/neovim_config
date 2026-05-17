local M = {}

---@class JestAssertion
---@field ancestorTitles string[]
---@field title string
---@field status string
---@field failureMessages string[]|nil
---@field console {message: string, type: string}[]|nil

---@class JestTestResult
---@field name string
---@field status string
---@field assertionResults JestAssertion[]

---@class JestJsonOutput
---@field numTotalTests number
---@field numPassedTests number
---@field numFailedTests number
---@field numPendingTests number
---@field testResults JestTestResult[]

---@class ParsedTestNode
---@field name string
---@field status string
---@field children ParsedTestNode[]|nil
---@field failureMessages string[]|nil
---@field console {message: string, type: string}[]|nil

---Parse raw jest --json stdout into a structured tree.
---Returns nil and an error message if parsing fails.
---@param json_string string
---@return ParsedResult|nil
---@return string|nil
function M.parse(json_string)
	if not json_string or json_string == "" then
		return nil, "Empty jest output"
	end

	-- jest may print non-json lines before/after the json (e.g. warnings)
	-- local start_idx = json_string:find("{%s*\"numTotalTests")
	-- local end_idx = json_string:find("}%s*$")
	-- if not start_idx then
	-- 	start_idx = json_string:find("{")
	-- end
	-- if not end_idx then
	-- 	local rev_end = json_string:reverse():find("}")
	-- 	if rev_end then
	-- 		end_idx = #json_string - rev_end + 1
	-- 	end
	-- end
	--
	local to_decode = json_string
	-- if start_idx and end_idx then
	-- 	to_decode = json_string:sub(start_idx, end_idx)
	-- end

	local ok, data = pcall(vim.json.decode, to_decode)
	if not ok or type(data) ~= "table" then
		return nil, "Failed to parse jest JSON output"
	end

	if not data.testResults or #data.testResults == 0 then
		return nil, "No test results found in jest output"
	end

	-- Merge multiple testResults entries into one tree.
	local summary = {
		passed = data.numPassedTests or 0,
		failed = data.numFailedTests or 0,
		pending = data.numPendingTests or 0,
	}

	local tree = {}

	for _, file_result in ipairs(data.testResults) do
		if file_result.assertionResults then
			for _, assertion in ipairs(file_result.assertionResults) do
				-- Build path through ancestorTitles
				local current_level = tree

				for _, ancestor in ipairs(assertion.ancestorTitles or {}) do
					local found = false
					for _, node in ipairs(current_level) do
						if node.name == ancestor then
							if not node.children then
								node.children = {}
							end
							current_level = node.children
							found = true
							break
						end
					end

					if not found then
						local new_node = {
							name = ancestor,
							status = assertion.status,
							children = {},
						}
						table.insert(current_level, new_node)
						current_level = new_node.children
					end
				end

				-- Insert the actual test
				table.insert(current_level, {
					name = assertion.title,
					status = assertion.status,
					failureMessages = assertion.failureMessages,
					console = assertion.console,
				})
			end
		end
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
