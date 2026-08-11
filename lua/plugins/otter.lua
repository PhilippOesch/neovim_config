--lsp embedding (javascript in html-script tag)

local opts = {
	lsp = {
		diagnostic_update_events = { "BufWritePost" },
	},
}

---@type Config.Plugin
return {
	deps = {
		"https://github.com/jmbuhr/otter.nvim",
	},
	init = function()
		local otter = require("otter")

		otter.setup(opts)

		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "html", "htm" },
			callback = function()
				otter.activate({ "javascript" }, true, true)
			end,
		})
	end,
}
