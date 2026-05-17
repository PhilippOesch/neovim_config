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
		local formatter = require('plugins.test-runner.formatter')
		local lines = vim.split(formatter.format("foo.spec.ts", nil, { icons = { pass = "P", fail = "F", pending = "S", suite = "SU" } }), "\n")
		return { lines[1], lines[3] }
	]])
	MiniTest.expect.equality(result[1], "# Test Results: foo.spec.ts")
	MiniTest.expect.equality(result[2], "## Running tests...")
end

T["formatter"]["format empty tree"] = function()
	local result = child.lua([[
		local formatter = require('plugins.test-runner.formatter')
		local md = formatter.format("foo.spec.ts", { summary = { passed = 0, failed = 0, pending = 0 }, tree = {} }, { icons = { pass = "P", fail = "F", pending = "S", suite = "SU" } })
		local lines = vim.split(md, "\n")
		return { lines[3], lines[5] }
	]])
	MiniTest.expect.equality(result[1], "**0 passed, 0 failed, 0 skipped**")
	MiniTest.expect.equality(result[2], "_No tests found._")
end

T["formatter"]["format renders tree with icons and suite icon"] = function()
	local result = child.lua([[
		local formatter = require('plugins.test-runner.formatter')
		local md = formatter.format("foo.spec.ts", {
			summary = { passed = 1, failed = 1, pending = 0 },
			tree = {
				{ name = "Suite", status = "failed", children = {
					{ name = "passes", status = "passed" },
					{ name = "fails", status = "failed", failureMessages = { "expected 1, got 2" } },
				} }
			}
		}, { icons = { pass = "P", fail = "F", pending = "S", suite = "SU" } })
		local lines = vim.split(md, "\n")
		return {
			summary = lines[3],
			suite = lines[5],
			pass = lines[6],
			fail = lines[7],
			fold_start = lines[8],
			code_block_start = lines[9],
			msg = lines[10],
			code_block_end = lines[11],
			fold_end = lines[12],
		}
	]])
	MiniTest.expect.equality(result.summary, "**1 passed, 1 failed, 0 skipped**")
	MiniTest.expect.equality(result.suite, "- SU F Suite")
	MiniTest.expect.equality(result.pass, "  - P passes")
	MiniTest.expect.equality(result.fail, "  - F fails")
	MiniTest.expect.equality(result.fold_start, "    <!-- {{{1 -->")
	MiniTest.expect.equality(result.code_block_start, "    ```")
	MiniTest.expect.equality(result.msg, "    expected 1, got 2")
	MiniTest.expect.equality(result.code_block_end, "    ```")
	MiniTest.expect.equality(result.fold_end, "    <!-- }}}1 -->")
end

T["formatter"]["format renders console for failed tests"] = function()
	local result = child.lua([[
		local formatter = require('plugins.test-runner.formatter')
		local md = formatter.format("foo.spec.ts", {
			summary = { passed = 0, failed = 1, pending = 0 },
			tree = {
				{ name = "fails", status = "failed", failureMessages = { "err" }, console = { { message = "log msg", type = "log" } } }
			}
		}, { icons = { pass = "P", fail = "F", pending = "S", suite = "SU" } })
		local lines = vim.split(md, "\n")
		return {
			fail_line = lines[5],
			fold_start = lines[6],
			code_start = lines[7],
			msg = lines[8],
			sep = lines[9],
			console = lines[10],
			code_end = lines[11],
			fold_end = lines[12],
		}
	]])
	MiniTest.expect.equality(result.fail_line, "- F fails")
	MiniTest.expect.equality(result.fold_start, "  <!-- {{{1 -->")
	MiniTest.expect.equality(result.code_start, "  ```")
	MiniTest.expect.equality(result.msg, "  err")
	MiniTest.expect.equality(result.sep, "  ---")
	MiniTest.expect.equality(result.console, "  [log] log msg")
	MiniTest.expect.equality(result.code_end, "  ```")
	MiniTest.expect.equality(result.fold_end, "  <!-- }}}1 -->")
end

T["formatter"]["format truncates long console output"] = function()
	local result = child.lua([[
		local formatter = require('plugins.test-runner.formatter')
		local long_msg = {}
		for i = 1, 25 do
			table.insert(long_msg, "line " .. i)
		end
		local md = formatter.format("foo.spec.ts", {
			summary = { passed = 0, failed = 1, pending = 0 },
			tree = {
				{ name = "fails", status = "failed", failureMessages = { table.concat(long_msg, "\n") } }
			}
		}, { icons = { pass = "P", fail = "F", pending = "S", suite = "SU" }, max_console_lines = 20 })
		local lines = vim.split(md, "\n")
		return {
			fail_line = lines[5],
			fold_start = lines[6],
			code_start = lines[7],
			-- line 8 = "  line 1", ... line 27 = "  line 20", line 28 = truncation notice
			truncation = lines[28],
			code_end = lines[29],
			fold_end = lines[30],
		}
	]])
	MiniTest.expect.equality(result.fail_line, "- F fails")
	MiniTest.expect.equality(result.fold_start, "  <!-- {{{1 -->")
	MiniTest.expect.equality(result.code_start, "  ```")
	MiniTest.expect.equality(result.truncation, "  ... (5 more lines)")
	MiniTest.expect.equality(result.code_end, "  ```")
	MiniTest.expect.equality(result.fold_end, "  <!-- }}}1 -->")
end

T["formatter"]["format uses custom icons"] = function()
	local result = child.lua([[
		local formatter = require('plugins.test-runner.formatter')
		local md = formatter.format("foo.spec.ts", {
			summary = { passed = 1, failed = 0, pending = 0 },
			tree = {
				{ name = "ok", status = "passed" }
			}
		}, { icons = { pass = "[OK]", fail = "[KO]", pending = "[SKIP]", suite = "[DIR]" } })
		local lines = vim.split(md, "\n")
		return { lines[5] }
	]])
	MiniTest.expect.equality(result[1], "- [OK] ok")
end

return T
