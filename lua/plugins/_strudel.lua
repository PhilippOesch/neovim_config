local function map(mode, lhs, rhs, desc, icon)
	vim.keymap.set(mode, lhs, rhs, { desc = desc })

	local wk_available, wk = pcall(require, "which-key")

	if wk_available then
		wk.add({
			{ lhs, icon = icon },
		})
	end
end

local function setup_strudel_keybinds()
	local strudel = require("strudel")

	local icon = ""

	map("n", "<leader>sl", strudel.launch, "Launch Strudel", icon)
	map("n", "<leader>sq", strudel.quit, "Quit Strudel", icon)
	map("n", "<leader>st", strudel.toggle, "Strudel Toggle Play/Stop", icon)
	map("n", "<leader>su", strudel.update, "Strudel Update", icon)
	map("n", "<leader>ss", strudel.stop, "Strudel Stop Playback", icon)
	map("n", "<leader>sb", strudel.set_buffer, "Strudel set current buffer", icon)
	map("n", "<leader>sx", strudel.execute, "Strudel set current buffer and update", icon)
end

return {
	"gruvw/strudel.nvim",
	build = "npm ci",
	config = function()
		require("strudel").setup({
			update_on_save = true,
		})
		vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
			pattern = "*.str",
			callback = function()
				-- when opened buffer anew
				setup_strudel_keybinds()
			end,
		})
		local group = vim.api.nvim_create_augroup("PersistedHooks", {})
		vim.api.nvim_create_autocmd({ "User" }, {
			pattern = "PersistedLoadPost",
			group = group,
			callback = function(args)
				-- when loading session
				local name = vim.api.nvim_buf_get_name(args.buf)

				if string.match(name, "%.str$") then
					setup_strudel_keybinds()
				end
			end,
		})
	end,
}
