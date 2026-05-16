---@type Config.Plugin
return {
	deps = { "https://github.com/PhilippOesch/lineforge.nvim" },
	init = function()
		local lineforge = require("lineforge")
		local segments = lineforge.segments

		lineforge.setup({
			---@param builder lineforge.Builder
			statusline = function(builder)
				builder
					---@param bld lineforge.Builder
					:section(function(bld)
						bld:wrap("", "", function(bld)
							segments.mode.add(bld)
						end, { fg = bld.ctx:get_highlight("Folded").bg })
						bld:add_space(" ", 2)
						segments.file_icon.add(bld)
						bld:add_space()
						segments.filename.add(bld, { fg = bld.ctx:get_highlight("Special").fg })
						bld:add_space(" ", 2)
						segments.git_branch.add(bld, { fg = bld.ctx:get_highlight("String").fg, bold = true })
						segments.git_status.add(bld)
					end)
					:section(
						---@param bld lineforge.Builder
						function(bld)
							segments.lsp_attached_info.add(
								bld,
								{ fg = bld.ctx:get_highlight("String").fg, bold = true }
							)
							bld:add_space(" ", 2)
							segments.fileformat.add(bld, { fg = bld.ctx:get_highlight("Normal").fg })
							bld:add_space(" ", 2)
							segments.ruler.add(bld)
							bld:add_space(" ", 2)
							segments.scrollbar.add(bld, {
								fg = bld.ctx:get_highlight("Directory").fg,
								bg = bld.ctx:get_highlight("Folded").bg,
							})
						end
					)
			end,
		})
	end,
}
