local MiniTest = require("mini.test")

local T = MiniTest.new_set()

local child = MiniTest.new_child_neovim()

T["parser"] = MiniTest.new_set({
	hooks = {
		pre_case = function()
			child.restart({ "-u", "scripts/minimal_init.lua" })
		end,
	},
})

T["parser"]["parse empty string returns error"] = function()
	local result = child.lua([[
		local parser = require('plugins.test-runner.adapters.parser')
		return { parser.parse("") }
	]])
	MiniTest.expect.equality(result[1], vim.NIL)
	MiniTest.expect.equality(result[2], "Empty jest output")
end

T["parser"]["parse invalid json returns error"] = function()
	local result = child.lua([[
		local parser = require('plugins.test-runner.adapters.parser')
		return { parser.parse("not json") }
	]])
	MiniTest.expect.equality(result[1], vim.NIL)
	MiniTest.expect.equality(result[2], "Failed to parse jest JSON output")
end

T["parser"]["parse valid jest json returns summary"] = function()
	local result = child.lua([[
		local parser = require('plugins.test-runner.adapters.parser')
		local json = vim.json.encode({
			numTotalTests = 3,
			numPassedTests = 2,
			numFailedTests = 1,
			numPendingTests = 0,
			testResults = {
				{
					name = "/tmp/foo.spec.ts",
					status = "failed",
					assertionResults = {
						{ ancestorTitles = {}, title = "passes", status = "passed", failureMessages = {} },
						{ ancestorTitles = {}, title = "fails", status = "failed", failureMessages = { "expected true" } },
						{ ancestorTitles = {}, title = "skipped", status = "pending", failureMessages = {} },
					}
				}
			}
		})
		local parsed, err = parser.parse(json)
		return {
			parsed = parsed ~= nil,
			passed = parsed and parsed.summary.passed or 0,
			failed = parsed and parsed.summary.failed or 0,
			pending = parsed and parsed.summary.pending or 0,
			tree_len = parsed and #parsed.tree or 0,
		}
	]])
	MiniTest.expect.equality(result.parsed, true)
	MiniTest.expect.equality(result.passed, 2)
	MiniTest.expect.equality(result.failed, 1)
	MiniTest.expect.equality(result.pending, 0)
	MiniTest.expect.equality(result.tree_len, 3)
end

T["parser"]["parse builds nested tree"] = function()
	local result = child.lua([[
		local parser = require('plugins.test-runner.adapters.parser')
		local json = vim.json.encode({
			numTotalTests = 2,
			numPassedTests = 1,
			numFailedTests = 1,
			numPendingTests = 0,
			testResults = {
				{
					name = "/tmp/foo.spec.ts",
					status = "failed",
					assertionResults = {
						{ ancestorTitles = {"Outer"}, title = "inner pass", status = "passed", failureMessages = {} },
						{ ancestorTitles = {"Outer"}, title = "inner fail", status = "failed", failureMessages = {"boom"} },
					}
				}
			}
		})
		local parsed = parser.parse(json)
		local tree = parsed.tree
		return {
			root_len = #tree,
			root_name = tree[1].name,
			root_status = tree[1].status,
			children_len = tree[1].children and #tree[1].children or 0,
			child1_name = tree[1].children[1].name,
			child1_status = tree[1].children[1].status,
			child2_name = tree[1].children[2].name,
			child2_status = tree[1].children[2].status,
			child2_msg = tree[1].children[2].failureMessages[1],
		}
	]])
	MiniTest.expect.equality(result.root_len, 1)
	MiniTest.expect.equality(result.root_name, "Outer")
	MiniTest.expect.equality(result.root_status, "failed") -- bubbled up
	MiniTest.expect.equality(result.children_len, 2)
	MiniTest.expect.equality(result.child1_name, "inner pass")
	MiniTest.expect.equality(result.child1_status, "passed")
	MiniTest.expect.equality(result.child2_name, "inner fail")
	MiniTest.expect.equality(result.child2_status, "failed")
	MiniTest.expect.equality(result.child2_msg, "boom")
end

T["parser"]["parse handles multiple test result entries"] = function()
	local result = child.lua([[
		local parser = require('plugins.test-runner.adapters.parser')
		local json = vim.json.encode({
			numTotalTests = 2,
			numPassedTests = 1,
			numFailedTests = 1,
			numPendingTests = 0,
			testResults = {
				{
					name = "/tmp/a.spec.ts",
					status = "passed",
					assertionResults = {
						{ ancestorTitles = {}, title = "a", status = "passed", failureMessages = {} },
					}
				},
				{
					name = "/tmp/b.spec.ts",
					status = "failed",
					assertionResults = {
						{ ancestorTitles = {}, title = "b", status = "failed", failureMessages = {"err"} },
					}
				}
			}
		})
		local parsed = parser.parse(json)
		return {
			tree_len = #parsed.tree,
			summary_passed = parsed.summary.passed,
			summary_failed = parsed.summary.failed,
		}
	]])
	MiniTest.expect.equality(result.tree_len, 2)
	MiniTest.expect.equality(result.summary_passed, 1)
	MiniTest.expect.equality(result.summary_failed, 1)
end

return T
