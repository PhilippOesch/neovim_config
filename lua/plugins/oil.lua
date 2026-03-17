return {
	"stevearc/oil.nvim",
	-- dir = "/Users/philippoeschger/dev/projects/oil.nvim/",
	dependencies = {
		{
			"refractalize/oil-git-status.nvim",
		},
	},
	lazy = false,
	config = function()
		require("oil").setup({
			default_file_explorer = false,
			keymaps = {
				["<C-p>"] = false,
				["<C-u>"] = { "actions.preview_scroll_up", desc = "scroll up in preview." },
				["<C-d>"] = { "actions.preview_scroll_down", desc = "scroll down in preview." },
				["<C-h>"] = false,
				["<C-l>"] = false,
				["<C-r>"] = { "actions.refresh", desc = "refresh oil buffer." },
				["<C-n>"] = false,
				["-"] = { "actions.parent", desc = "navigate to parent path." },
				["<leader>p"] = { "actions.preview", desc = "toggle preview" },
			},
			win_options = {
				signcolumn = "yes:2",
			},
			columns = {
				"icon",
			},
			view_options = {
				show_hidden = true,
				natural_order = true,
				sort_case_insensitive = true,
			},
			float = {
				-- Padding around the floating window
				padding = 5,
				max_width = 0,
				max_height = 0,
				get_win_title = function(winid)
					return ""
				end,
				border = "rounded",
				win_options = {
					winblend = 0,
				},
				preview_split = "right",
				-- This is the config that will be passed to nvim_open_win.
				-- Change values here to customize the layout
				override = function(conf)
					return conf
				end,
			},
		})
		require("oil-git-status").setup()
		-- keymaps
		vim.keymap.set("n", "<leader>-", function()
			require("oil").toggle_float()
		end, {
			noremap = true,
			desc = "open oil",
		})
		vim.keymap.set("n", "<C-n>", function()
			require("oil").toggle_float(".")
		end, {
			noremap = true,
			desc = "open oil cwd",
		})
		vim.keymap.set("n", "-", "<CMD>Oil<CR>", {
			noremap = true,
			desc = "open oil",
		})

		require("which-key").add({ {
			"<leader>-",
			icon = "󰙅",
		} })
	end,
}
