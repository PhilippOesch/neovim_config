return {
	"obsidian-nvim/obsidian.nvim",
	lazy = true,
	opts = {

		workspaces = {
			{
				name = "personal",
				path = "~/Documents/ObsidianVault/",
			},
		},
		completion = {
			-- Set to false to disable completion.
			nvim_cmp = false,
			blink = true,
			-- Trigger completion at 2 chars.
			min_chars = 1,
		},
		ui = {
			enable = true,
		},
		footer = {
			enabled = false,
		},
		legacy_commands = false,
		-- see below for full list of options 👇
		attachments = {
			-- The default folder to place images in via `:ObsidianPasteImg`.
			-- If this is a relative path it will be interpreted as relative to the vault root.
			-- You can always override this per image by passing a full path to the command instead of just a filename.
			img_folder = "files/imgs", -- This is the default
			-- A function that determines the text to insert in the note when pasting an image.
			-- It takes two arguments, the `obsidian.Client` and an `obsidian.Path` to the image file.
			-- This is the default implementation.
			---@param client obsidian.Client
			---@param path obsidian.Path the absolute path to the image file
			---@return string
			img_text_func = function(client, path)
				path = client:vault_relative_path(path) or path
				return string.format("![%s](%s)", path.name, path)
			end,
		},
	},
	ft = "markdown",
}
