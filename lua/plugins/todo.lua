---@type Config.Plugin
return {
	init = function()
		local todo = require("plugins.todo.init")
		todo.setup()

		vim.keymap.set("n", "<leader>do", function()
			todo.toggle()
		end, { noremap = true, desc = "Toggle todo" })

		require("which-key").add({
			{
				"<leader>do",
				icon = "",
			},
		})
	end,
}
