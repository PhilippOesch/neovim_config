local dap = require("dap")
local map = vim.keymap.set
--
map("n", "<F5>", dap.continue, {
	noremap = true,
	desc = "Debug: Start/Continue",
})
map("n", "<F4>", dap.step_into, {
	noremap = true,
	desc = "Debug: Step Into",
})
map("n", "<F10>", dap.step_over, {
	noremap = true,
	desc = "Debug: Step Over",
})
map("n", "<F3>", dap.step_out, {
	noremap = true,
	desc = "Debug: Step Out",
})
map("n", "<leader>b", dap.toggle_breakpoint, {
	noremap = true,
	desc = "Debug: Toggle Breakpoint",
})
map("n", "<leader>B", function()
	dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, {
	noremap = true,
	desc = "Debug: Set Breakpoint",
})
map("n", "<F8>", function()
	dap.disconnect({ terminateDebugger = true })
end, {
	noremap = true,
	desc = "Debug: Terminate session.",
})
map("n", "<F7>", function()
	dap.toggle()
end, {
	noremap = true,
	desc = "Debug: See last session result.",
})
map("n", "<leader>fh", function()
	dap.hover()
end, {
	noremap = true,
	desc = "Debug: hover",
})
