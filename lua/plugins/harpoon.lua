require("harpoon").setup({
	menu = {
		width = vim.api.nvim_win_get_width(0) - 4,
	},
})
--
local fmt = string.format
local wk = require("which-key")
--
-- keymaps
vim.keymap.set("n", "<leader>h", function()
	require("harpoon.ui").toggle_quick_menu()
end, {
	noremap = true,
	desc = "Open Harpoon Marks View",
})
vim.keymap.set("n", "<leader>'", function()
	require("harpoon.mark").add_file()
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
		require("harpoon.ui").nav_file(i)
	end, {
		noremap = true,
		desc = fmt(markDescBase, i),
	})
	wk.add({
		{ fmt("<leader>%d", i), icon = "" },
	})
end
