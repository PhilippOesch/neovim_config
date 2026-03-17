local dap = require("dap")
local home = os.getenv("HOME")

local M = {}

--
local function get_debugger()
	-- return home .. "/dev/projects/netcoredbg/build/src/netcoredbg"
	return "/usr/local/netcoredbg"
end

function M.init()
	dap.adapters.coreclr = {
		type = "executable",
		command = get_debugger(),
		args = { "--interpreter=vscode" },
	}

	dap.adapters.netcoredbg = { type = "executable", command = get_debugger(), args = { "--interpreter=vscode" } }

	dap.configurations.cs = {
		{
			type = "coreclr",
			name = "launch - netcoredbg",
			request = "launch",
			program = function()
				return vim.fn.input("Path to dll", vim.fn.getcwd() .. "/bin/Debug/", "file")
			end,
		},
		{
			type = "coreclr",
			name = "Attach - netcoredbg",
			request = "attach",
			processId = require("dap.utils").pick_process,
		},
	}
end

return M;
