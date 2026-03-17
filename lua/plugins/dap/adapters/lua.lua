local dap = require("dap")
local debugger_path = vim.fs.joinpath(vim.fn.stdpath("data") .. "/lazy", "local-lua-debugger-vscode/")
local executablePath = vim.fs.joinpath(debugger_path .. "/extension", "debugAdapter.js")

local M = {}

function M.init()
	dap.adapters["local-lua"] = {
		type = "executable",
		command = "node",
		args = {
			executablePath,
		},
		enrich_config = function(config, on_config)
			if not config["extensionPath"] then
				local c = vim.deepcopy(config)
				-- 💀 If this is missing or wrong you'll see
				-- "module 'lldebugger' not found" errors in the dap-repl when trying to launch a debug session
				c.extensionPath = debugger_path
				on_config(c)
			else
				on_config(config)
			end
		end,
	}

	dap.configurations.lua = {
		{
			name = "Current file (local-lua-dbg, lua)",
			type = "local-lua",
			request = "launch",
			cwd = "${workspaceFolder}",
			program = {
				lua = "lua5.4",
				file = "${file}",
			},
			args = {},
		},
	}
end

return M
