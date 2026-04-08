local dap = require("dap")
local dapui = require("dapui")
local utils = require("utils")

require("nvim-dap-virtual-text").setup({})

local adapters = utils.requireAll("plugins.dap.adapters")

for _, l in pairs(adapters) do
	l.init()
end

-- Dap UI setup
-- For more information, see |:help nvim-dap-ui|
dapui.setup({
	-- Set icons to characters that are more likely to work in every terminal.
	--    Feel free to remove or use ones that you like more! :)
	--    Don't feel like these are good choices.
	icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
	controls = {
		icons = {
			pause = "⏸",
			play = "▶",
			step_into = "⏎",
			step_over = "⏭",
			step_out = "⏮",
			step_back = "b",
			run_last = "▶▶",
			terminate = "⏹",
			disconnect = "⏏",
		},
	},
})

dap.listeners.after.event_initialized["dapui_config"] = dapui.open
dap.listeners.before.event_terminated["dapui_config"] = dapui.close
dap.listeners.before.event_exited["dapui_config"] = dapui.close

vim.fn.sign_define("DapBreakpoint", { text = "⬤", texthl = "DapBreakpoint" })

require("plugins.dap.setup.keymaps")
