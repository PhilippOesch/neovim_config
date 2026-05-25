local DadbodSource = {}

DadbodSource.name = "dadbod"

local map_kind_to_cmp_lsp_kind = {
	F = 3, -- Function -> Function
	C = 5, -- Column -> Field
	A = 6, -- Alias -> Variable
	T = 7, -- Table -> Class
	R = 14, -- Reserved -> Keyword
	S = 19, -- Schema -> Folder
}

---@param params lsp.CompletionParams
---@param context table
---@return lsp.CompletionItem[]
function DadbodSource.get_completions(params, context)
	local items = {}

	local prefix = context.line_to_cursor:match("[%w_]+$") or ""
	local results = vim.fn["vim_dadbod_completion#omni"](0, prefix)

	for _, item in ipairs(results) do
		table.insert(items, {
			label = item.abbr,
			dup = 0,
			insertText = item.word,
			labelDetails = {
				description = item.menu,
			},
			documentation = item.info,
			kind = map_kind_to_cmp_lsp_kind[item.kind],
		})
	end

	return items
end

return DadbodSource
