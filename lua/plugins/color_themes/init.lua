return {
	-- {
	-- 	"PhilippOesch/jaoti-theme",
	-- 	dependencies = { "rktjmp/lush.nvim" },
	-- 	config = function()
	-- 		vim.cmd.colorscheme("jaoti")
	-- 		local c = 't'
	-- 	end,
	-- },
	-- {
	-- 	-- dir = "~/dev/projects/notechbase.nvim",
	-- 	"mcauley-penney/techbase.nvim",
	-- 	opts = {
	-- 		italic_comments = true,
	-- 	},
	-- 	config = function(_, opts)
	-- 		-- local techbase = require("techbase")
	-- 		-- techbase.setup(opts)
	-- 		-- techbase.load("techbase-hc")
	-- 		--
	-- 		-- vim.cmd.colorscheme("techbase-hc")
	-- 		--
	-- 		-- vim.g.terminal_color_0 = "#191d23"
	-- 		-- vim.g.terminal_color_1 = "#f71735"
	-- 		-- vim.g.terminal_color_2 = "#74baa8"
	-- 		-- vim.g.terminal_color_3 = "#e9b872"
	-- 		-- vim.g.terminal_color_4 = "#a9b9ef"
	-- 		-- vim.g.terminal_color_5 = "#bcb6ec"
	-- 		-- vim.g.terminal_color_6 = "#1a8c9b"
	-- 		-- vim.g.terminal_color_7 = "#ccd5e5"
	-- 		-- vim.g.terminal_color_8 = "#474b65"
	-- 		-- vim.g.terminal_color_9 = "#ffc0c5"
	-- 		-- vim.g.terminal_color_10 = "#0ec256"
	-- 		-- vim.g.terminal_color_11 = "#ffa630"
	-- 		-- vim.g.terminal_color_12 = "#6a8be3"
	-- 		-- vim.g.terminal_color_13 = "#d6ddea"
	-- 		-- vim.g.terminal_color_14 = "#5dcd9a"
	-- 		-- vim.g.terminal_color_15 = "#d6ddea"
	-- 	end,
	-- 	priority = 1000,
	-- },
	-- {
	-- 	"https://github.com/navarasu/onedark.nvim",
	-- 	config = function(_, opts)
	-- 		-- require("onedark").setup({
	-- 		-- 	style = "darker",
	-- 		-- })
	-- 		-- Enable theme
	-- 		-- require("onedark").load()
	-- 		-- vim.api.nvim_set_hl(0, "Winbar", { link = "Normal" })
	-- 		-- vim.api.nvim_set_hl(0, "WinbarNC", { link = "NormalNC" })
	-- 	end,
	-- 	priority = 1000,
	-- },
	{
		"folke/tokyonight.nvim",
		lazy = true,
		priority = 1000,
		config = function()
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
		end,
	},
	-- {
	-- 	"serhez/teide.nvim",
	-- 	lazy = false,
	-- 	priority = 1000,
	-- 	opts = {},
	-- 	config = function()
	-- 		local teide = require("teide")
	--
	-- 		local opts = {
	-- 			-- style = "moon",
	-- 			transparent = false,
	-- 			styles = {
	-- 				comments = { italic = true },
	-- 				keywords = { italic = true },
	-- 			},
	-- 			on_highlights = function(highlights, colors)
	-- 				highlights.LineNr0 = {
	-- 					fg = colors.red,
	-- 				}
	-- 				highlights.SnacksPickerBorder = {
	-- 					bg = colors.border,
	-- 					fg = colors.border,
	-- 				}
	-- 				highlights.SnacksPickerPreview = {
	-- 					bg = colors.bg_dark1,
	-- 				}
	-- 				highlights.SnacksPickerInputBorder = {
	-- 					bg = colors.bg_statusline,
	-- 					fg = colors.bg_popup,
	-- 				}
	-- 				highlights.SnacksPickerTitle = {
	-- 					bg = colors.border,
	-- 				}
	-- 				highlights.SnacksPickerPreviewTitle = {
	-- 					bg = colors.border,
	-- 				}
	-- 			end,
	-- 		}
	-- 		teide.setup(opts)
	-- 		teide.load(opts)
	-- 	end,
	-- },
}
