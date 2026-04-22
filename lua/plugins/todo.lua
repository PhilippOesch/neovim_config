---@type Config.Plugin
return {
	init = function()
		local todo = require("plugins.todo.init")
		todo.setup({ todo_file = vim.g.todo_path or require("plugins.todo.config").get_default_config().todo_file })

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
