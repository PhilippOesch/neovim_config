return {
	"rebelot/heirline.nvim",
	config = function()
		local conditions = require("heirline.conditions")
		local utils = require("heirline.utils")

		local function setup_colors()
			return {
				bright_bg = utils.get_highlight("Folded").bg or utils.get_highlight("Normal").bg,
				bright_fg = utils.get_highlight("Folded").fg,
				red = utils.get_highlight("DiagnosticError").fg,
				dark_red = utils.get_highlight("DiffDelete").bg,
				green = utils.get_highlight("String").fg,
				blue = utils.get_highlight("Directory").fg,
				gray = utils.get_highlight("NonText").fg,
				orange = utils.get_highlight("Constant").fg,
				purple = utils.get_highlight("Statement").fg,
				cyan = utils.get_highlight("Special").fg,
				diag_warn = utils.get_highlight("DiagnosticWarn").fg,
				diag_error = utils.get_highlight("DiagnosticError").fg,
				diag_hint = utils.get_highlight("DiagnosticHint").fg,
				diag_info = utils.get_highlight("DiagnosticInfo").fg,
				git_del = utils.get_highlight("DiffDelete").fg
					or utils.get_highlight("diffRemoved").fg
					or utils.get_highlight("DiffDeleted").fg,
				git_add = utils.get_highlight("DiffAdd").fg or utils.get_highlight("diffAdded").fg,
				git_change = utils.get_highlight("DiffChange").fg or utils.get_highlight("diffChanged").fg,
			}
		end

		local Align = { provider = "%=" }
		local Space = { provider = "  ", hl = { fg = "gray" } }

		local Qflist = {
			condition = function(self)
				return vim.bo.filetype == "qf"
			end,
			hl = { fg = "cyan", bold = true, force = true },
			provider = "Quickfix List:",
		}

		local Llist = {
			condition = function(self)
				return vim.bo.filetype == "qf"
			end,
			hl = { fg = "cyan", bold = true, force = true },
			provider = "Local List:",
		}

		local ignore_list = { "snacks_dashboard" }
		IgnoreWinBar = {
			condition = function(self)
				return vim.tbl_contains(ignore_list, vim.bo.filetype)
			end,
			provider = nil,
		}

		local tool_list = { "lazy", "mason", "mcphub", "oil_preview", "harpoon" }
		local Tool = {
			condition = function(self)
				return vim.tbl_contains(tool_list, vim.bo.filetype)
			end,
			utils.insert({
				hl = { fg = "cyan", force = true },
				{
					provider = function(self)
						return string.format(" %s", self.filetype)
					end,
				},
			}),
		}

		local web_icons_available, web_icons = pcall(require, "nvim-web-devicons")

		local FileName = {
			init = function(self)
				self.lfilename = vim.fn.fnamemodify(self.filename, ":.")
				if self.lfilename == "" then
					self.lfilename = "[No Name]"
				end
			end,
			hl = { fg = "blue" },

			flexible = 2,

			{
				provider = function(self)
					return self.lfilename
				end,
			},
			{
				provider = function(self)
					return vim.fn.pathshorten(self.lfilename)
				end,
			},
		}

		-- Now, let's say that we want the filename color to change if the buffer is
		-- modified. Of course, we could do that directly using the FileName.hl field,
		-- but we'll see how easy it is to alter existing components using a "modifier"
		-- component

		-- I take no credits for this! 🦁
		local ScrollBar = {
			static = {
				sbar = { " ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" },
				-- Another variant, because the more choice the better.
				-- sbar = { '🭶', '🭷', '🭸', '🭹', '🭺', '🭻' }
			},
			provider = function(self)
				local curr_line = vim.api.nvim_win_get_cursor(0)[1]
				local lines = vim.api.nvim_buf_line_count(0)
				local i = math.floor((curr_line - 1) / lines * #self.sbar) + 1
				return string.rep(self.sbar[i], 2)
			end,
			hl = { fg = "blue", bg = "bright_bg" },
		}
		-- We're getting minimalist here!
		local Ruler = {
			-- %l = current line number
			-- %L = number of lines in the buffer
			-- %c = column number
			-- %P = percentage through file of displayed window
			provider = "%7(%l/%3L%):%2c %P",
		}

		local HelpFileName = {
			condition = function()
				return vim.bo.filetype == "help"
			end,
			provider = function()
				local filename = vim.api.nvim_buf_get_name(0)
				return vim.fn.fnamemodify(filename, ":t")
			end,
			hl = { fg = "blue" },
		}
		local Spell = {
			condition = function()
				return vim.wo.spell
			end,
			provider = "SPELL ",
			hl = { bold = true, fg = "orange" },
		}

		local mode = require("plugins.heirline.vimode")
		ViMode = utils.surround({ "", "" }, "bright_bg", { mode })
		local file = require("plugins.heirline.file")
		local InactiveStatusline = {
			condition = conditions.is_not_active,
			file.Type,
			Space,
			FileName,
			Align,
		}

		local codecompanion = require("plugins.heirline.codecompanion")

		local SpecialStatusline = {
			condition = function()
				return conditions.buffer_matches({
					buftype = { "nofile", "prompt", "help", "quickfix" },
					filetype = { "^git.*", "fugitive" },
				})
			end,

			file.Type,
			Space,
			HelpFileName,
			Align,
			codecompanion.Adapter,
			Space,
			codecompanion.Model,
			Space,
			codecompanion.Mode,
			Space,
			codecompanion.Billing,
			Align,
			codecompanion.Chat,
			Space,
			codecompanion.Status,
		}

		local lsp = require("plugins.heirline.lsp")
		local dap = require("plugins.heirline.dap")
		local Git = require("plugins.heirline.git")
		local navic = require("plugins.heirline.navic")

		local DefaultStatusLine = {
			ViMode,
			Space,
			Git,
			Space,
			lsp.Diagnostics,
			Space,
			navic,
			Align,
			dap.Messages,
			Spell,
			Align,
			lsp.LSPActive,
			Space,
			lsp.LSPMessages,
			Space,
			file.Format,
			Space,
			file.Type,
			Space,
			Ruler,
			Space,
			ScrollBar,
		}

		local oil = require("plugins.heirline.oil")

		local WinBars = {
			init = function(self)
				self.filetype = vim.bo.filetype
			end,
			fallthrough = false,
			IgnoreWinBar,
			oil.OilPreview,
			Qflist,
			Llist,
			Tool,
			oil.OilBlock,
			codecompanion.Title,
			{ -- A special winbar for terminals
				condition = function()
					return conditions.buffer_matches({ buftype = { "terminal" } })
				end,
				file.Type,
			},
			{ -- An inactive winbar for regular files
				condition = function()
					return not conditions.is_active()
				end,
				utils.insert({ hl = { fg = "gray", force = true }, file.NameBlock }),
			},
			-- A winbar for regular files
			file.NameBlock,
		}

		local StatusLines = {

			hl = function()
				if conditions.is_active() then
					return "StatusLine"
				else
					return "StatusLineNC"
				end
			end,

			-- the first statusline with no condition, or which condition returns true is used.
			-- think of it as a switch case with breaks to stop fallthrough.
			fallthrough = false,

			SpecialStatusline,
			InactiveStatusline,
			DefaultStatusLine,
		}

		require("heirline").setup({
			statusline = StatusLines,
			winbar = WinBars,
			opts = {
				colors = setup_colors(),
				disable_winbar_cb = function(args)
					local buf = args.buf
					local buftype = vim.tbl_contains({ "prompt", "nofile", "help" }, vim.bo.buftype)
					local filetype =
						vim.tbl_contains({ "gitcommit", "fugitive", "Trouble", "packer", "dashboard" }, vim.bo.filetype)
					local include = vim.tbl_contains({ "codecompanion" }, vim.bo.filetype)
					return (buftype or filetype) and not include
				end,
			},
		})

		local group = vim.api.nvim_create_augroup("Heirline", { clear = true })
		vim.api.nvim_create_autocmd("ColorScheme", {
			callback = function()
				utils.on_colorscheme(setup_colors)
			end,
			group = group,
		})
	end,
}
