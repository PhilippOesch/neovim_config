return {
	init = function()
		local highlight = require("plugins.statusline.highlight")

		require("plugins.statusline.init").setup({
			statusline = function(builder)
				builder
					:add_surround("", "", function(bld)
						bld:add_mode()
					end, { fg = highlight.get_highlight("Folded").bg })
					:add_space()
					:add_filename()
			end,
		})
	end,
}
