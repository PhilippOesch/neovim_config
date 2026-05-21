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
		local parser = require('plugins.test-runner.adapters.mini.parser')
		return { parser.parse("") }
	]])
	MiniTest.expect.equality(result[1], vim.NIL)
	MiniTest.expect.equality(result[2], "Empty mini.test output")
end

T["parser"]["parse invalid json returns error"] = function()
	local result = child.lua([[
		local parser = require('plugins.test-runner.adapters.mini.parser')
		return { parser.parse("not json") }
	]])
	MiniTest.expect.equality(result[1], vim.NIL)
	MiniTest.expect.equality(result[2], "Failed to parse mini.test JSON output")
end

T["parser"]["parse error envelope returns error"] = function()
	local result = child.lua([[
		local parser = require('plugins.test-runner.adapters.mini.parser')
		local json = vim.json.encode({ ok = false, error = "Something went wrong" })
		return { parser.parse(json) }
	]])
	MiniTest.expect.equality(result[1], vim.NIL)
	MiniTest.expect.equality(result[2], "Something went wrong")
end

T["parser"]["parse empty cases returns error"] = function()
	local result = child.lua([[
		local parser = require('plugins.test-runner.adapters.mini.parser')
		local json = vim.json.encode({ ok = true, cases = {} })
		return { parser.parse(json) }
	]])
	MiniTest.expect.equality(result[1], vim.NIL)
	MiniTest.expect.equality(result[2], "No test cases found in mini.test output")
end

T["parser"]["parse single flat case returns summary and tree"] = function()
	local result = child.lua([[
		local parser = require('plugins.test-runner.adapters.mini.parser')
		local json = vim.json.encode({
			ok = true,
			cases = {
				{ desc = { "basic math works" }, state = "Pass", fails = {}, notes = {}, args = {} },
			},
		})
		local parsed, err = parser.parse(json)
		return {
			parsed = parsed ~= nil,
			passed = parsed and parsed.summary.passed or 0,
			failed = parsed and parsed.summary.failed or 0,
			pending = parsed and parsed.summary.pending or 0,
			tree_len = parsed and #parsed.tree or 0,
			leaf_name = parsed and parsed.tree[1].name,
			leaf_status = parsed and parsed.tree[1].status,
		}
	]])
	MiniTest.expect.equality(result.parsed, true)
	MiniTest.expect.equality(result.passed, 1)
	MiniTest.expect.equality(result.failed, 0)
	MiniTest.expect.equality(result.pending, 0)
	MiniTest.expect.equality(result.tree_len, 1)
	MiniTest.expect.equality(result.leaf_name, "basic math works")
	MiniTest.expect.equality(result.leaf_status, "passed")
end

T["parser"]["parse nested desc builds tree"] = function()
	local result = child.lua([[
		local parser = require('plugins.test-runner.adapters.mini.parser')
		local json = vim.json.encode({
			ok = true,
			cases = {
				{ desc = { "parser", "handles pass" }, state = "Pass", fails = {}, notes = {}, args = {} },
				{ desc = { "parser", "handles fail" }, state = "Fail", fails = { "expected 2, got 3" }, notes = {}, args = {} },
			},
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
	MiniTest.expect.equality(result.root_name, "parser")
	MiniTest.expect.equality(result.root_status, "failed")
	MiniTest.expect.equality(result.children_len, 2)
	MiniTest.expect.equality(result.child1_name, "handles pass")
	MiniTest.expect.equality(result.child1_status, "passed")
	MiniTest.expect.equality(result.child2_name, "handles fail")
	MiniTest.expect.equality(result.child2_status, "failed")
	MiniTest.expect.equality(result.child2_msg, "expected 2, got 3")
end

T["parser"]["parse handles multiple top-level cases"] = function()
	local result = child.lua([[
		local parser = require('plugins.test-runner.adapters.mini.parser')
		local json = vim.json.encode({
			ok = true,
			cases = {
				{ desc = { "a" }, state = "Pass", fails = {}, notes = {}, args = {} },
				{ desc = { "b" }, state = "Fail", fails = { "err" }, notes = {}, args = {} },
			},
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

T["parser"]["parse maps nil state to pending"] = function()
	local result = child.lua([[
		local parser = require('plugins.test-runner.adapters.mini.parser')
		local json = vim.json.encode({
			ok = true,
			cases = {
				{ desc = { "skipped" }, state = vim.NIL, fails = {}, notes = {}, args = {} },
			},
		})
		local parsed = parser.parse(json)
		return {
			pending = parsed.summary.pending,
			status = parsed.tree[1].status,
		}
	]])
	MiniTest.expect.equality(result.pending, 1)
	MiniTest.expect.equality(result.status, "pending")
end

T["parser"]["parse handles notes in state"] = function()
	local result = child.lua([[
		local parser = require('plugins.test-runner.adapters.mini.parser')
		local json = vim.json.encode({
			ok = true,
			cases = {
				{ desc = { "with notes" }, state = "Pass with notes", fails = {}, notes = { "note 1" }, args = {} },
				{ desc = { "fail with notes" }, state = "Fail with notes", fails = { "boom" }, notes = { "note 2" }, args = {} },
			},
		})
		local parsed = parser.parse(json)
		return {
			pass_status = parsed.tree[1].status,
			fail_status = parsed.tree[2].status,
			fail_msg = parsed.tree[2].failureMessages[1],
		}
	]])
	MiniTest.expect.equality(result.pass_status, "passed")
	MiniTest.expect.equality(result.fail_status, "failed")
	MiniTest.expect.equality(result.fail_msg, "boom")
end

return T
