local luasnip = require("luasnip")

local M = {}

M.name = "luasnip"

---Normalize a snippet docstring to a table of lines.
---@param doc string|string[]
---@return string[]
local function normalize_docstring(doc)
	if type(doc) == "string" then
		return { doc }
	end
	return doc
end

---@param item lsp.CompletionItem
---@return lsp.CompletionItem
function M.resolve(item)
	if item.data and item.data.snip_id then
		local snip = luasnip.get_id_snippet(item.data.snip_id)
		if snip then
			item.detail = snip.name
			item.documentation = {
				kind = "markdown",
				value = "```" .. (item.data.filetype or "") .. "\n"
					.. table.concat(normalize_docstring(snip:get_docstring()), "\n")
					.. "\n```",
			}
		end
	end
	return item
end

---@param params lsp.CompletionParams
---@param context table
---@return lsp.CompletionItem[]
function M.get_completions(params, context)
	local bufnr = context.bufnr

	local prefix = context.line_to_cursor:match("[%w_]+$") or ""

	local ok, luasnip_util = pcall(require, "luasnip.util.util")
	local filetypes
	if ok then
		filetypes = luasnip_util.get_snippet_filetypes()
	else
		filetypes = { vim.api.nvim_get_option_value("filetype", { buf = bufnr }), "all" }
	end

	local items = {}
	local seen_ids = {}

	for _, ft in ipairs(filetypes) do
		local snippets = luasnip.get_snippets(ft, { type = "snippets" }) or {}
		for _, snip in pairs(snippets) do
			-- Skip hidden, invalidated, or already-seen snippets.
			if snip.hidden or snip.invalidated or seen_ids[snip.id] then
				goto next_snip
			end

			-- When a prefix is typed, only literal triggers that match it.
			if prefix ~= "" then
				if snip.regTrig or snip.trigger:sub(1, #prefix) ~= prefix then
					goto next_snip
				end
			end

			if snip.show_condition and not snip.show_condition(context.line_to_cursor) then
				goto next_snip
			end

			seen_ids[snip.id] = true

			local body = table.concat(normalize_docstring(snip:get_docstring()), "\n")

			local priority = snip.effective_priority or 1000
			local sort_text = string.format("%04d", 10000 - priority) .. snip.trigger

			local start_char = params.position.character - #prefix
			local item = {
				label = snip.trigger,
				kind = vim.lsp.protocol.CompletionItemKind.Snippet,
				sortText = sort_text,
				insertTextFormat = vim.lsp.protocol.InsertTextFormat.Snippet,
				textEdit = {
					range = {
						start = {
							line = params.position.line,
							character = start_char,
						},
						["end"] = {
							line = params.position.line,
							character = params.position.character,
						},
					},
					newText = body,
				},
				data = {
					snip_id = snip.id,
					filetype = ft,
				},
			}

			table.insert(items, item)

			::next_snip::
		end
	end

	return items
end

return M
