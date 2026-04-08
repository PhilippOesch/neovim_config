local opts = {
	bigfile = { enabled = true },
	dashboard = { enabled = false },
	explorer = { enabled = false },
	image = {
		enabled = true,
		formats = {
			"png",
			"jpg",
			"jpeg",
			"gif",
			"bmp",
			"webp",
			"tiff",
			"heic",
			"avif",
			"mp4",
			"mov",
			"avi",
			"mkv",
			"webm",
			"pdf",
		},
		force = true, -- try displaying the image, even if the terminal does not support it
		doc = {
			-- enable image viewer for documents
			-- a treesitter parser must be available for the enabled languages.
			-- supported language injections: markdown, html
			enabled = true,
			-- render the image inline in the buffer
			-- if your env doesn't support unicode placeholders, this will be disabled
			-- takes precedence over `opts.float` on supported terminals
			inline = true,
			-- render the image in a floating window
			-- only used if `opts.inline` is disabled
			float = true,
			max_width = 80,
			max_height = 40,
		},
	},
	layout = { enable = false },
	indent = { enabled = true },
	input = { enabled = true },
	zen = {
		enabled = true,
		show = {
			statusline = true, -- can only be shown when using the global statusline
			tabline = false,
		},
	},
	picker = {
		enabled = true,
		main = {
			file = false,
			current = true,
		},
		layout = {
			default = {
				box = "horizontal",
				width = 0.8,
				min_width = 120,
				height = 0.8,
				{
					box = "vertical",
					border = true,
					title = "{title} {live} {flags}",
					{ win = "input", height = 1, border = true },
					{ win = "list", border = "none" },
				},
				{ win = "preview", title = "{preview}", border = true, width = 0.5 },
			},
		},
		win = {
			input = {
				keys = {
					["<C-j>"] = { "history_forward", mode = { "i", "n" } },
					["<C-k>"] = { "history_back", mode = { "i", "n" } },
				},
			},
		},
	},
	terminal = { enable = false },
	notifier = { enabled = true },
	quickfile = { enabled = true },
	scope = { enabled = false },
	win = { enabled = true },
	scroll = {
		enabled = true,
		animate = {
			duration = { step = 15, total = 100 },
			easing = "linear",
		},
		-- faster animation when repeating scroll after delay
		animate_repeat = {
			delay = 100, -- delay in ms before using the repeat animation
			duration = { step = 5, total = 50 },
			easing = "linear",
		},
	},
	statuscolumn = { enabled = true },
	words = { enabled = false },
	---@type table<string, snacks.win.Config>
	styles = {
		zen = {
			backdrop = { transparent = false, blend = 40 },
		},
		input = {
			border = true,
			position = "float",
			backdrop = true,
		},
	},
}

local snacks = require("snacks")
snacks.setup(opts)

local map = vim.keymap.set

map("n", "<leader><space>", snacks.picker.buffers, { noremap = true, desc = "Find Open Buffers" })
map("n", "<C-p>", snacks.picker.files, { noremap = true, desc = "Find Files" })
map("n", "<leader>fp", function()
	snacks.picker.projects({
		projects = { "~/.config/nvim", "~/Documents/ObsidianVault" },
		dev = { "~/dev/projects/", "~/.config/" },
	})
end, { noremap = true, desc = "Projects" })
map("n", "<leader>fw", snacks.picker.grep, { noremap = true, desc = "Grep" })
map("n", "<leader>:", snacks.picker.command_history, { noremap = true, desc = "command history" })
map("n", "<leader>fr", snacks.picker.recent, { noremap = true, desc = "Recent" })
map("n", "<leader>sC", snacks.picker.commands, { noremap = true, desc = "Commands" })
map("n", "<leader>sj", snacks.picker.jumps, { noremap = true, desc = "Jumps" })
map("n", "<leader>su", snacks.picker.undo, { noremap = true, desc = "Undo History" })
map({ "n", "x" }, "<leader>sw", snacks.picker.grep_word, { noremap = true, desc = "Visual selection or word" })
map("n", "<leader>lg", function()
	snacks.lazygit()
end, { noremap = true, desc = "Lazygit" })
map("n", "<leader>gl", snacks.picker.git_log, { noremap = true, desc = "Git Log" })
map("n", "<leader>gs", snacks.picker.git_status, { noremap = true, desc = "Git Status" })
map("n", "<leader>gd", snacks.picker.git_diff, { noremap = true, desc = "Git Diff (Hunks)" })
map("n", "gd", snacks.picker.lsp_definitions, { noremap = true, desc = "Goto Definition" })
map("n", "gD", snacks.picker.lsp_declarations, { noremap = true, desc = "Goto Declaration" })
map("n", "gr", snacks.picker.lsp_references, { noremap = true, nowait = true, desc = "References" })
map("n", "gI", snacks.picker.lsp_implementations, { noremap = true, desc = "Goto Implementation" })
map("n", "gy", snacks.picker.lsp_type_definitions, { noremap = true, desc = "Goto T[y]pe Definition" })
map("n", "<leader>ss", snacks.picker.lsp_symbols, { noremap = true, desc = "LSP Symbols" })
map("n", "<leader>sS", snacks.picker.lsp_workspace_symbols, { noremap = true, desc = "LSP Workspace Symbols" })
map("n", "<leader>pc", snacks.picker.colorschemes, { noremap = true, desc = "LSP Workspace Symbols" })
map("n", "<leader>sd", snacks.picker.diagnostics, { noremap = true, desc = "Diagnostics" })
map("n", "<leader>sD", snacks.picker.diagnostics_buffer, { noremap = true, desc = "Buffer Diagnostics" })
map("n", "<leader>sh", snacks.picker.help, { noremap = true, desc = "Help Pages" })
map("n", '<leader>s"', snacks.picker.registers, { noremap = true, desc = "Registers" })
map("n", "<leader>sH", snacks.picker.highlights, { noremap = true, desc = "Highlights" })
map("n", "<leader>xx", snacks.bufdelete.all, { noremap = true, desc = "LSP Workspace Symbols" })
map("n", "<leader>x", function()
	snacks.bufdelete()
end, { noremap = true, desc = "LSP Workspace Symbols" })
map("n", "<leader>z", function()
	snacks.zen()
end, { noremap = true, desc = "Toggle Zen Mode" })
map("n", "<leader>n", snacks.picker.notifications, { noremap = true, desc = "Notification History" })
