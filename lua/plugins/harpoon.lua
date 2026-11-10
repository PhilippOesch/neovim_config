return {
	deps = {
		{ src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2" },
		"https://github.com/nvim-lua/plenary.nvim",
	},
	init = function()
		local harpoon = require("harpoon")
		harpoon:setup()

		local fmt = string.format
		local wk = require("which-key")
		--
		-- keymaps
		vim.keymap.set("n", "<leader>o", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end, {
			noremap = true,
			desc = "Open Harpoon Marks View",
		})
		vim.keymap.set("n", "<leader>'", function()
			harpoon:list():add()
		end, {
			noremap = true,
			desc = "Create Mark",
		})
		wk.add({
			{ "<leader>h", icon = "󰸕" },
			{ "<leader>'", icon = "" },
		})

		local markDescBase = "Go to mark %d"
		for i = 1, 9, 1 do
			vim.keymap.set("n", fmt("<leader>%d", i), function()
				harpoon:list():select(i)
			end, {
				noremap = true,
				desc = fmt(markDescBase, i),
			})
			wk.add({
				{ fmt("<leader>%d", i), icon = "" },
			})
		end
	end,
}
