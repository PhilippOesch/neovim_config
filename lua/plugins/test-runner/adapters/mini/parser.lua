--- Parser for mini.test JSON output
---
--- Consumes the JSON envelope printed by the generated runner script and
--- produces a ParsedResult tree suitable for the shared formatter.

local M = {}

---Bubble failed status up from children to parent suites.
---@param nodes ParsedTestNode[]
local function bubble_status(nodes)
	for _, node in ipairs(nodes) do
		if node.children then
			bubble_status(node.children)
			for _, child in ipairs(node.children) do
				if child.status == "failed" then
					node.status = "failed"
					break
				end
			end
		end
	end
end

---Insert a case into the tree at the correct depth based on its desc array.
---@param tree ParsedTestNode[]
---@param desc string[]
---@param status string
---@param messages string[]
local function insert_case(tree, desc, status, messages)
	local current = tree
	for i = 1, #desc - 1 do
		local name = desc[i]
		local found = nil
		for _, child in ipairs(current) do
			if child.name == name and child.children then
				found = child
				break
			end
		end
		if not found then
			found = { name = name, status = "passed", children = {} }
			table.insert(current, found)
		end
		current = found.children
	end
	table.insert(current, {
		name = desc[#desc],
		status = status,
		failureMessages = messages,
	})
end

---Map mini.test exec.state to ParsedResult status.
---@param state string|nil
---@return string
local function map_status(state)
	if state == "Pass" or state == "Pass with notes" then
		return "passed"
	elseif state == "Fail" or state == "Fail with notes" then
		return "failed"
	elseif state == nil then
		return "pending"
	else
		return "pending"
	end
end

---Parse the JSON output from the mini.test runner script.
---@param raw string
---@return ParsedResult|nil, string|nil
M.parse = function(raw)
	if not raw or raw == "" then
		return nil, "Empty mini.test output"
	end

	local ok, data = pcall(vim.json.decode, raw)
	if not ok or not data then
		return nil, "Failed to parse mini.test JSON output"
	end

	if not data.ok then
		return nil, data.error or "mini.test runner reported an error"
	end

	local cases = data.cases or {}
	if #cases == 0 then
		return nil, "No test cases found in mini.test output"
	end

	local tree = {}
	local passed, failed, pending = 0, 0, 0

	for _, case in ipairs(cases) do
		local status = map_status(case.state)
		if status == "passed" then
			passed = passed + 1
		elseif status == "failed" then
			failed = failed + 1
		else
			pending = pending + 1
		end

		local desc = case.desc or {}
		if #desc == 0 then
			table.insert(desc, "(unnamed)")
		end

		local messages = {}
		if case.fails then
			for _, msg in ipairs(case.fails) do
				table.insert(messages, msg)
			end
		end

		insert_case(tree, desc, status, messages)
	end

	bubble_status(tree)

	return {
		summary = { passed = passed, failed = failed, pending = pending },
		tree = tree,
	}, nil
end

return M
