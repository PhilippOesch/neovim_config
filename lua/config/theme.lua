local tokyonight = require("tokyonight")

local opts = {
	style = "moon",
	transparent = false,
	styles = {
		comments = { italic = true },
		keywords = { italic = true },
	},
	on_highlights = function(highlights, colors)
		highlights.LineNr0 = {
			fg = colors.red,
		}
		highlights.SnacksPickerBorder = {
			bg = colors.border,
			fg = colors.border,
		}
		highlights.SnacksPickerPreview = {
			bg = colors.bg_dark1,
		}
		highlights.SnacksPickerInputBorder = {
			bg = colors.bg_statusline,
			fg = colors.bg_popup,
		}
		highlights.SnacksPickerTitle = {
			bg = colors.border,
		}
		highlights.SnacksPickerPreviewTitle = {
			bg = colors.border,
		}
	end,
}
tokyonight.setup(opts)
tokyonight.load(opts)

vim.cmd.colorscheme("tokyonight")
