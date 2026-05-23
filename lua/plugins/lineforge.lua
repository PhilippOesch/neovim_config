---@type Config.Plugin
return {
	deps = {
		{ src = "https://github.com/PhilippOesch/lineforge.nvim" },
	},
	init = function()
		local lineforge = require("lineforge")
		local segments = lineforge.segments

		local oil_available, oilnvim = pcall(require, "oil")

		local oilSegment = {
			---@param bld lineforge.Builder
			add = function(bld)
				bld:when(function()
					return oil_available and vim.bo.filetype == "oil"
				end, function(bld)
					bld:add(function()
						local pathFormat = ":p:~:."
						local dir = oilnvim.get_current_dir()
						local bufName
						if dir then
							bufName = vim.fn.fnamemodify(dir, pathFormat)
						else
							bufName = vim.api.nvim_buf_get_name(0)
						end

						if bufName == "" then
							return " ./"
						end
						return " " .. bufName
					end, { fg = bld.ctx:get_highlight("Directory").fg })
				end)
			end,
		}

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
						oilSegment.add(bld)
						segments.file_icon.add(bld, { ignore_filetypes = { "oil" } })
						bld:add_space()
						segments.filename.add(bld, {
							hl = { fg = bld.ctx:get_highlight("Special").fg },
							ignore_filetypes = { "oil" },
							max_width = 50,
						})
						bld:add_space(" ", 2)
						segments.git_branch.add(
							bld,
							{ hl = { fg = bld.ctx:get_highlight("String").fg, bold = true }, max_width = 50 }
						)
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
