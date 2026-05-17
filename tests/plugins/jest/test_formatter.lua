local MiniTest = require("mini.test")

local T = MiniTest.new_set()

local child = MiniTest.new_child_neovim()

T["formatter"] = MiniTest.new_set({
	hooks = {
		pre_case = function()
			child.restart({ "-u", "scripts/minimal_init.lua" })
		end,
	},
})

T["formatter"]["format running state"] = function()
	local result = child.lua([[
		local formatter = require('plugins.jest.formatter')
		local lines = vim.split(formatter.format("foo.spec.ts", nil, { icons = { pass = "P", fail = "F", pending = "S" } }), "\n")
		return { lines[1], lines[3] }
	]])
	MiniTest.expect.equality(result[1], "# Test Results: foo.spec.ts")
	MiniTest.expect.equality(result[2], "## Running tests...")
end

T["formatter"]["format empty tree"] = function()
	local result = child.lua([[
		local formatter = require('plugins.jest.formatter')
		local md = formatter.format("foo.spec.ts", { summary = { passed = 0, failed = 0, pending = 0 }, tree = {} }, { icons = { pass = "P", fail = "F", pending = "S" } })
		local lines = vim.split(md, "\n")
		return { lines[3], lines[5] }
	]])
	MiniTest.expect.equality(result[1], "**0 passed, 0 failed, 0 skipped**")
	MiniTest.expect.equality(result[2], "_No tests found._")
end

T["formatter"]["format renders tree with icons"] = function()
	local result = child.lua([[
		local formatter = require('plugins.jest.formatter')
		local md = formatter.format("foo.spec.ts", {
			summary = { passed = 1, failed = 1, pending = 0 },
			tree = {
				{ name = "Suite", status = "failed", children = {
					{ name = "passes", status = "passed" },
					{ name = "fails", status = "failed", failureMessages = { "expected 1, got 2" } },
				} }
			}
		}, { icons = { pass = "P", fail = "F", pending = "S" } })
		local lines = vim.split(md, "\n")
		return {
			summary = lines[3],
			suite = lines[5],
			pass = lines[6],
			fail = lines[7],
			code_block_start = lines[8],
		}
	]])
	MiniTest.expect.equality(result.summary, "**1 passed, 1 failed, 0 skipped**")
	MiniTest.expect.equality(result.suite, "- F Suite")
	MiniTest.expect.equality(result.pass, "  - P passes")
	MiniTest.expect.equality(result.fail, "  - F fails")
	MiniTest.expect.equality(result.code_block_start, "    ```")
end

T["formatter"]["format renders console for failed tests"] = function()
	local result = child.lua([[
		local formatter = require('plugins.jest.formatter')
		local md = formatter.format("foo.spec.ts", {
			summary = { passed = 0, failed = 1, pending = 0 },
			tree = {
				{ name = "fails", status = "failed", failureMessages = { "err" }, console = { { message = "log msg", type = "log" } } }
			}
		}, { icons = { pass = "P", fail = "F", pending = "S" } })
		local lines = vim.split(md, "\n")
		return {
			fail_line = lines[5],
			code_start = lines[6],
			msg = lines[7],
			sep = lines[8],
			console = lines[9],
			code_end = lines[10],
		}
	]])
	MiniTest.expect.equality(result.fail_line, "- F fails")
	MiniTest.expect.equality(result.code_start, "  ```")
	MiniTest.expect.equality(result.msg, "  err")
	MiniTest.expect.equality(result.sep, "  ---")
	MiniTest.expect.equality(result.console, "  [log] log msg")
	MiniTest.expect.equality(result.code_end, "  ```")
end

T["formatter"]["format uses custom icons"] = function()
	local result = child.lua([[
		local formatter = require('plugins.jest.formatter')
		local md = formatter.format("foo.spec.ts", {
			summary = { passed = 1, failed = 0, pending = 0 },
			tree = {
				{ name = "ok", status = "passed" }
			}
		}, { icons = { pass = "[OK]", fail = "[KO]", pending = "[SKIP]" } })
		local lines = vim.split(md, "\n")
		return { lines[5] }
	]])
	MiniTest.expect.equality(result[1], "- [OK] ok")
end

return T
