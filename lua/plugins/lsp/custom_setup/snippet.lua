local M = {}

local luasnip = require("luasnip")

local COMPLETION_KIND_SNIPPET = 15
local INSERT_FORMAT_SNIPPET = 2

-- Trigger characters for completion autotrigger (a-z, A-Z, _).
local TRIGGER_CHARS = {
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
	"n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
	"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
	"_",
}

---Normalize a snippet docstring to a table of lines.
---@param doc string|string[]
---@return string[]
local function normalize_docstring(doc)
	if type(doc) == "string" then
		return { doc }
	end
	return doc
end

---@param dispatchers vim.lsp.rpc.Dispatchers
---@return vim.lsp.rpc.PublicClient
local function cmd_fn(dispatchers)
	local closing = false
	local request_id = 0

	---@type vim.lsp.rpc.PublicClient
	local srv = {}

	function srv.request(method, params, callback)
		if method == "initialize" then
			callback(nil, {
				capabilities = {
					completionProvider = {
						triggerCharacters = TRIGGER_CHARS,
						resolveProvider = true,
					},
				},
			})
		elseif method == "shutdown" then
			callback(nil, nil)
		elseif method == "textDocument/completion" then
			---@cast params lsp.CompletionParams
			local file_path = params.textDocument.uri:gsub("^file://", "")
			local bufnr = vim.fn.bufnr(file_path)
			if bufnr == -1 then
				bufnr = 0
			end

			local line = vim.api.nvim_buf_get_lines(
				bufnr,
				params.position.line,
				params.position.line + 1,
				false
			)[1] or ""
			local line_to_cursor = line:sub(1, params.position.character)
			local prefix = line_to_cursor:match("[%w_]+$") or ""

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

					if snip.show_condition and not snip.show_condition(line_to_cursor) then
						goto next_snip
					end

					seen_ids[snip.id] = true

					local body = table.concat(normalize_docstring(snip:get_docstring()), "\n")

					local priority = snip.effective_priority or 1000
					local sort_text = string.format("%04d", 10000 - priority) .. snip.trigger

					local start_char = params.position.character - #prefix
					local item = {
						label = snip.trigger,
						kind = COMPLETION_KIND_SNIPPET,
						sortText = sort_text,
						insertTextFormat = INSERT_FORMAT_SNIPPET,
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

			callback(nil, {
				items = items,
				isIncomplete = false,
			})
		elseif method == "completionItem/resolve" then
			---@cast params lsp.CompletionItem
			local item = params
			if item.data and item.data.snip_id then
				local snip = luasnip.get_id_snippet(item.data.snip_id)
				if snip then
					item.detail = snip.name
					item.documentation = {
						kind = "markdown",
						value = "```" .. (item.data.filetype or "") .. "\n" .. table.concat(normalize_docstring(snip:get_docstring()), "\n") .. "\n```",
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
