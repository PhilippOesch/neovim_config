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

---@type Config.Plugin
return {
	deps = {
		"https://github.com/scottmckendry/cyberdream.nvim",
		"https://github.com/folke/tokyonight.nvim",
		"https://github.com/navarasu/onedark.nvim",
		"https://github.com/olivercederborg/poimandres.nvim",
	},
	init = function()
		--cyberdream
		require("cyberdream").setup()

		--tokyonight
		local tokyonight = require("tokyonight")
		tokyonight.setup(opts)

		--onedark
		require("onedark").setup({
			style = "deep",
		})

		--poimandres
		require("poimandres").setup({
		})

		-- set cyberdream
		-- vim.cmd.colorscheme("cyberdream")

		-- set tokyonight
		tokyonight.load(opts)
		vim.cmd.colorscheme("tokyonight")

		-- set onedark
		-- require("onedark").load()
		-- vim.cmd.colorscheme("onedark")
		
		-- -- set poimandres
		-- vim.cmd.colorscheme("poimandres")
	end,
}
