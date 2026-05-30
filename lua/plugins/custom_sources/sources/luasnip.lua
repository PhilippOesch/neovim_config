local luasnip = require("luasnip")

local LuaSnipSource = {}

LuaSnipSource.name = "luasnip"

local kind_snippet = vim.lsp.protocol.CompletionItemKind.Snippet

---Normalize a snippet docstring to a table of lines.
---@param doc string|string[]
---@return string[]
local function normalize_docstring(doc)
	if type(doc) == "string" then
		return { doc }
	end
	return doc
end

local function indent_text(lines, indent)
	if #lines == 0 then
		return ""
	end
	local text = table.concat(lines, "\n")
	return text:gsub("\n", "\n" .. indent)
end

---@param snippet LuaSnip.Snippet
---@param indent? string
---@return string
local function get_insert_text(snippet, indent)
	indent = indent or ""

	if snippet.docTrig then
		return snippet.docTrig
	end
	if snippet.regTrig then
		return snippet.trigger
	end
	if not snippet.nodes then
		return snippet.trigger
	end

	local types = require("luasnip.util.types")
	local res = {}
	for _, node in ipairs(snippet.nodes) do
		if node.static_text then
			res[#res + 1] = indent_text(node:get_static_text(), indent)
		elseif vim.tbl_contains({ types.dynamicNode, types.functionNode }, node.type) then
			res[#res + 1] = "..."
		end
	end

	return #res == 1 and snippet.trigger or table.concat(res, "")
end

---@param item lsp.CompletionItem
---@return lsp.CompletionItem
function LuaSnipSource.resolve(item)
	local snip = luasnip.get_id_snippet(item.data.snip_id)

	local resolved_item = vim.deepcopy(item)

	---@type string|string[]|nil
	local detail = snip:get_docstring()
	if type(detail) == "table" then
		detail = table.concat(detail, "\n")
	end
	resolved_item.detail = detail

	if snip.dscr then
		resolved_item.documentation = {
			kind = "markdown",
			value = table.concat(vim.lsp.util.convert_input_to_markdown_lines(snip.dscr), "\n"),
		}
	end
	return item
end

---@param params lsp.CompletionParams
---@param context custom_source.Context
---@return lsp.CompletionItem[]
function LuaSnipSource.get_completions(params, context)
	---@type lsp.CompletionItem[]
	local items = {}

	if luasnip.choice_active() then
		---@type LuaSnip.ChoiceNode
		local active_choice = luasnip.session.active_choice_nodes[context.bufnr]
		for i, choice in ipairs(active_choice.choices) do
			local text = choice.static_text and choice:get_static_text()[1] or ""
			table.insert(items, {
				label = text,
				kind = kind_snippet,
				insertText = text,
				insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
				data = { snip_id = active_choice.parent.snippet.id, choice_index = i },
			})
		end
		return items
	end

	local events = require("luasnip.util.events")

	for _, ft in ipairs(luasnip.get_snippet_filetypes()) do
		local snippets = luasnip.get_snippets(ft, { type = "snippets" })
		snippets = vim.tbl_filter(function(snip)
			return not snip.hidden
		end, snippets)
		local max_priority = 0
		for _, snip in ipairs(snippets) do
			max_priority = math.max(max_priority, snip.effective_priority or 0)
		end
		for _, snip in ipairs(snippets) do
			---@cast snip LuaSnip.Snippet

			-- Convert priority of 1000 (with max of 8000) to string like "00007000|||asd" for sorting
			-- This will put high priority snippets at the top of the list, and break ties based on the trigger
			local inversed_priority = max_priority - (snip.effective_priority or 0)
			local sort_text = ("0"):rep(8 - #tostring(inversed_priority), "")
				.. inversed_priority
				.. "|||"
				.. snip.trigger

			--- @type lsp.CompletionItem
			local item = {
				kind = kind_snippet,
				label = snip.regTrig and snip.name or snip.trigger,
				insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
				sortText = sort_text,
				data = {
					snip_id = snip.id,
					show_condition = snip.show_condition,
					raw_text = get_insert_text(snip),
				},
				labelDetails = snip.dscr and {
					description = table.concat(snip.dscr, " "),
				} or nil,
			}

			table.insert(items, item)
		end
	end

	items = vim.tbl_filter(function(item)
		return item.data.show_condition(context.line_to_cursor)
	end, items)

	for _, item in ipairs(items) do
		item.insertText = item.data.raw_text
	end
	return items
end

return LuaSnipSource
