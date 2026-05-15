return {
	init = function()
		local highlight = require("plugins.statusline.highlight")

		require("plugins.statusline.init").setup({
			statusline = function(builder)
				builder
					:add_block(
						---@param bld Builder
						function(bld)
							bld:add_surround("", "", function(bld)
								bld:add_mode()
							end, { fg = highlight.get_highlight("Folded").bg })
								:add_space(" ", 2)
								:add_file_icon()
								:add_space(" ", 2)
								:add_filename({ fg = highlight.get_highlight("Special").fg })
								:add_space(" ", 2)
								:add_git_branch({ fg = highlight.get_highlight("String").fg })
						end
					)
					:add_block(
						---@param bld Builder
						function(bld)
							bld:add_lsp_attached_info({ fg = highlight.get_highlight("String").fg })
								:add_space(" ", 2)
								:add_ruler()
								:add_space(" ", 2)
								:add_scrollbar({
									fg = highlight.get_highlight("Directory").fg,
									bg = highlight.get_highlight("Folded").bg,
								})
						end
					)
			end,
		})
	end,
}
