return {
	init = function()
		local highlight = require("plugins.statusline.highlight")

		require("plugins.statusline.init").setup({
			statusline = function(builder)
				builder
					:add_block(function(bld)
						bld:add_surround("", "", function(bld)
							bld:add_mode()
						end, { fg = highlight.get_highlight("Folded").bg })
							:add_space()
							:add_filename()
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
