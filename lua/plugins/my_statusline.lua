return {
	init = function()
		local highlight = require("plugins.statusline.highlight")

		require("plugins.statusline.init").setup({
			statusline = function(builder)
				builder
					:add_block(function(bld)
						bld:add_surround("", "", function(inner)
							inner:add_mode()
						end, { fg = highlight.get_highlight("Folded").bg })
							:add_space()
							-- :add_hl_start({ fg = highlight.get_highlight("Special").fg })
							:add_filename()
						-- :add_hl_end()
					end)
					:add_block(function(bld)
						bld:add_ruler():add_space():add_scrollbar({
							fg = highlight.get_highlight("Directory").fg,
							bg = highlight.get_highlight("Folded").bg,
						})
					end)
			end,
		})
	end,
}
