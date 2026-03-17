local dap = require("dap")

local M = {}

function M.init()
	local install_location = require("mason-core.installer.InstallLocation")
	local jspath = install_location.global():package("js-debug-adapter")
	local firefoxPath = install_location.global():package("firefox-debug-adapter")
	-- print(path)

	dap.adapters["pwa-node"] = {
		type = "server",
		host = "localhost",
		port = "${port}",
		executable = {
			command = "node",
			-- 💀 Make sure to update this path to point to your installation
			args = { jspath .. "/js-debug/src/dapDebugServer.js", "${port}" },
		},
	}
	dap.adapters.firefox = {
		type = "executable",
		command = "node",
		args = { firefoxPath .. "/dist/adapter.bundle.js" },
	}

	for _, language in ipairs({ "typescript", "javascript", "javascriptreact", "typescriptreact", "svelte" }) do
		dap.configurations[language] = {
			{
				-- use nvim-dap-vscode-js's pwa-node debug adapter
				type = "pwa-node",
				-- attach to an already running node process with --inspect flag
				-- default port: 9222
				request = "attach",
				-- allows us to pick the process using a picker
				processId = require("dap.utils").pick_process,
				-- name of the debug action you have to select for this config
				name = "Attach debugger to existing `node --inspect` process",
				-- for compiled languages like TypeScript or Svelte.js
				sourceMaps = true,
				-- resolve source maps in nested locations while ignoring node_modules
				resolveSourceMapLocations = {
					"${workspaceFolder}/**",
					"!**/node_modules/**",
				},
				-- path to src in vite based projects (and most other projects as well)
				cwd = "${workspaceFolder}/src",
				-- we don't want to debug code inside node_modules, so skip it!
				skipFiles = { "${workspaceFolder}/node_modules/**/*.js" },
			},
			{
				name = "Debug React with Firefox",
				type = "firefox",
				request = "launch",
				reAttach = true,
				url = "http://localhost:3000",
				webRoot = "${workspaceFolder}",
				firefoxExecutable = "/Applications/Firefox Developer Edition.app/Contents/MacOS/firefox",
			},
		}
	end
end

return M
