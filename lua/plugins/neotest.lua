vim.pack.add({
	"https://github.com/nvim-neotest/neotest",
	"https://github.com/nvim-neotest/nvim-nio",
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/antoinemadec/FixCursorHold.nvim",
	"https://github.com/haydenmeade/neotest-jest",
	"https://github.com/Nsidorenco/neotest-vstest",
	"https://github.com/rcasia/neotest-java",
	"https://github.com/nvim-neotest/neotest-go",
	"https://github.com/marilari88/neotest-vitest",
}, { confirm = false })

require("neotest").setup({
	loglevel = 1,
	adapters = {
		-- require("neotest-dotnet")({
		-- 	discovery_root = "solution",
		-- }),
		require("neotest-vstest")({
			-- Path to dotnet sdk path.
			-- Used in cases where the sdk path cannot be auto discovered.
			-- sdk_path = "/usr/local/dotnet/sdk/9.0.101/",
			-- table is passed directly to DAP when debugging tests.
			dap_settings = {
				type = "netcoredbg",
			},
			-- If multiple solutions exists the adapter will ask you to choose one.
			-- If you have a different heuristic for choosing a solution you can provide a function here.
			solution_selector = function(solutions)
				return nil -- return the solution you want to use or nil to let the adapter choose.
			end,
		}),
		require("neotest-go"),
		require("neotest-jest")({
			jestCommand = "npm test --",
			env = { CI = true },
			cwd = function(_)
				return vim.fn.getcwd()
			end,
		}),
		require("neotest-vitest"),
		require("neotest-java")({
			ignore_wrapper = false,
		}),
	},
})

--neotest
vim.keymap.set("n", "<leader>tea", function()
	require("neotest").run.attach()
end, {
	noremap = true,
	desc = "Test Attach",
})
vim.keymap.set("n", "<leader>ter", function()
	require("neotest").run.run()
end, {
	noremap = true,
	desc = "Run Nearest Test",
})
vim.keymap.set("n", "<leader>tef", function()
	require("neotest").run.run(vim.fn.expand("%"))
end, {
	noremap = true,
	desc = "Run all tests in file.",
})
vim.keymap.set("n", "<leader>tes", function()
	require("neotest").summary.toggle()
end, {
	noremap = true,
	desc = "Open Test summary.",
})
vim.keymap.set("n", "<leader>tedf", function()
	require("neotest").run.run({ vim.fn.expand("%"), strategy = "dap" })
end, {
	noremap = true,
	desc = "Debug Test file",
})
vim.keymap.set("n", "<leader>tedn", function()
	require("neotest").run.run({ strategy = "dap" })
end, {
	noremap = true,
	desc = "Debug Nearest",
})
vim.keymap.set("n", "<leader>tet", function()
	require("neotest").run.stop()
end, {
	noremap = true,
	desc = "Terminate/Stop",
})
vim.keymap.set("n", "<leader>tel", function()
	require("neotest").run.run_last()
end, {
	noremap = true,
	desc = "Run last",
})
vim.keymap.set("n", "<leader>tedl", function()
	require("neotest").run.run_last({ strategy = "dap" })
end, {
	noremap = true,
	desc = "Debug last",
})
