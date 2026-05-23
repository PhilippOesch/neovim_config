local M = {}

---Build trigger characters for completion autotrigger.
---Includes a-z, A-Z, and underscore.
---@return string[]
local function build_trigger_chars()
	local chars = {}
	for i = string.byte("a"), string.byte("z") do
		table.insert(chars, string.char(i))
	end
	for i = string.byte("A"), string.byte("Z") do
		table.insert(chars, string.char(i))
	end
	table.insert(chars, "_")
	return chars
end

---@param dispatchers vim.lsp.rpc.Dispatchers
---@return vim.lsp.rpc.PublicClient
local function cmd_fn(dispatchers)
	local closing = false
	local request_id = 0

	local trigger_chars = build_trigger_chars()

	---@type vim.lsp.rpc.PublicClient
	local srv = {}

	function srv.request(method, params, callback)
		if method == "initialize" then
			callback(nil, {
				capabilities = {
					completionProvider = {
						triggerCharacters = trigger_chars,
						resolveProvider = true,
					},
				},
			})
		elseif method == "shutdown" then
			callback(nil, nil)
		elseif method == "textDocument/completion" then
			local typed_params = params ---@type lsp.CompletionParams
			local file_path = typed_params.textDocument.uri:gsub("^file://", "")
			local bufnr = vim.fn.bufnr(file_path)
			if bufnr == -1 then
				bufnr = 0
			end

			local line = vim.api.nvim_buf_get_lines(
				bufnr,
				typed_params.position.line,
				typed_params.position.line + 1,
				false
			)[1] or ""
			local line_to_cursor = line:sub(1, typed_params.position.character)
			local prefix = line_to_cursor:match("[%w_]+$") or ""

			local luasnip = require("luasnip")
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
					if snip.hidden or snip.invalidated then
						goto next_snip
					end

					-- When a prefix is typed, only literal triggers that match it.
					if prefix ~= "" then
						if snip.regTrig then
							goto next_snip
						end
						if snip.trigger:sub(1, #prefix) ~= prefix then
							goto next_snip
						end
					end

					if snip.show_condition and not snip.show_condition(line_to_cursor) then
						goto next_snip
					end

					if seen_ids[snip.id] then
						goto next_snip
					end
					seen_ids[snip.id] = true

					local docstring = snip:get_docstring()
					if type(docstring) == "string" then
						docstring = { docstring }
					end
					local body = table.concat(docstring, "\n")

					local priority = snip.effective_priority or 1000
					local sort_text = string.format("%04d", 10000 - priority) .. snip.trigger

					local start_char = typed_params.position.character - #prefix
					local item = {
						label = snip.trigger,
						kind = 15, -- Snippet
						sortText = sort_text,
						insertTextFormat = 2, -- Snippet
						textEdit = {
							range = {
								start = {
									line = typed_params.position.line,
									character = start_char,
								},
								["end"] = {
									line = typed_params.position.line,
									character = typed_params.position.character,
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

			callback(nil, {
				items = items,
				isIncomplete = false,
			})
		elseif method == "completionItem/resolve" then
			local item = params ---@type lsp.CompletionItem
			if item.data and item.data.snip_id then
				local snip = require("luasnip").get_id_snippet(item.data.snip_id)
				if snip then
					item.detail = snip.name
					local docstring = snip:get_docstring()
					if type(docstring) == "string" then
						docstring = { docstring }
					end
					item.documentation = {
						kind = "markdown",
						value = "```" .. (item.data.filetype or "") .. "\n" .. table.concat(docstring, "\n") .. "\n```",
					}
				end
			end
			callback(nil, item)
		end

		request_id = request_id + 1
		return true, request_id
	end

	function srv.notify(method, params)
		if method == "exit" then
			dispatchers.on_exit(0, 15)
		end
	end

	function srv.is_closing()
		return closing
	end

	function srv.terminate()
		closing = true
	end

	return srv
end

function M.init()
	local luasnip = require("luasnip")

	luasnip.filetype_extend("javascriptreact", { "html" })
	luasnip.filetype_extend("typescriptreact", { "html" })
	luasnip.filetype_extend("htmlangular", { "html" })
	luasnip.filetype_extend("vue", { "html" })
	luasnip.filetype_extend("todo", { "markdown" })

	require("luasnip.loaders.from_vscode").lazy_load()
	require("luasnip.loaders.from_vscode").load({ paths = { "./snippets" } })

	luasnip.config.setup()
	vim.lsp.config["luasnip-server"] = {
		cmd = cmd_fn,
		root_dir = function(bufnr, on_dir)
			on_dir(vim.fn.getcwd())
		end,
	}
	vim.lsp.enable("luasnip-server")
end

return M
