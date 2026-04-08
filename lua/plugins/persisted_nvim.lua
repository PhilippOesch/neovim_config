local opts = {

	autostart = true, -- Automatically start the plugin on load?

	-- Function to determine if a session should be saved
	---@type fun(): boolean
	should_save = function()
		return vim.bo.buftype ~= "terminal"
	end,

	save_dir = vim.fn.expand(vim.fn.stdpath("data") .. "/sessions/"), -- Directory where session files are saved

	follow_cwd = true, -- Change the session file to match any change in the cwd?
	use_git_branch = true, -- Include the git branch in the session file name?
	autoload = true, -- Automatically load the session for the cwd on Neovim startup?

	-- Function to run when `autoload = true` but there is no session to load
	---@type fun(): any
	on_autoload_no_session = function() end,

	allowed_dirs = {}, -- Table of dirs that the plugin will start and autoload from
	ignored_dirs = {}, -- Table of dirs that are ignored for starting and autoloading

	telescope = {
		mappings = { -- Mappings for managing sessions in Telescope
			copy_session = "<C-c>",
			change_branch = "<C-b>",
			delete_session = "<C-d>",
		},
		icons = { -- icons displayed in the Telescope picker
			selected = " ",
			dir = "  ",
			branch = " ",
		},
	},
}

require("persisted").setup(opts)

local group = vim.api.nvim_create_augroup("PersitedHooks", {})

vim.api.nvim_create_autocmd({ "User" }, {
	pattern = "PersistedSavePre",
	group = group,
	callback = function()
		local cc_available, codecompanion = pcall(require, "codecompanion")

		if cc_available then
			codecompanion.close_last_chat()
		end

		local opencode_available, opencode = pcall(require, "opencode")

		if opencode_available then
			opencode.stop()
		end
	end,
})
