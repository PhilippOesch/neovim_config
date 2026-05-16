return {
	init = function()
		local highlight = require("plugins.statusline.highlight")
		local segments = require("plugins.statusline.segments")

		require("plugins.statusline.init").setup({
			statusline = function(builder)
				builder
					:add_block(
						---@param bld Builder
						function(bld)
							bld:add_surround("", "", function(bld)
								segments.mode.add(bld)
							end, { fg = highlight.get_highlight("Folded").bg })
							bld:add_space(" ", 2)
							segments.file_icon.add(bld)
							bld:add_space()
							segments.filename.add(bld, { fg = highlight.get_highlight("Special").fg })
							bld:add_space(" ", 2)
							segments.git_branch.add(bld, { fg = highlight.get_highlight("String").fg, bold = true })
							segments.git_status.add(bld)
						end
					)
					:add_block(
						---@param bld Builder
						function(bld)
							segments.lsp_attached_info.add(
								bld,
								{ fg = highlight.get_highlight("String").fg, bold = true }
							)
							bld:add_space(" ", 2)
							segments.fileformat.add(bld, { fg = highlight.get_highlight("Normal").fg })
							bld:add_space(" ", 2)
							segments.ruler.add(bld)
							bld:add_space(" ", 2)
							segments.scrollbar.add(bld, {
								fg = highlight.get_highlight("Directory").fg,
								bg = highlight.get_highlight("Folded").bg,
							})
						end
					)
			end,
		})
	end,
}
