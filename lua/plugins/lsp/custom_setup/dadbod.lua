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

local map_kind_to_cmp_lsp_kind = {
	F = 3, -- Function -> Function
	C = 5, -- Column -> Field
	A = 6, -- Alias -> Variable
	T = 7, -- Table -> Class
	R = 14, -- Reserved -> Keyword
	S = 19, -- Schema -> Folder
}

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
						triggerCharacters = build_trigger_chars(),
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
			local results = vim.fn["vim_dadbod_completion#omni"](0, prefix)
			local items = {}
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

			callback(nil, {
				items = items,
				isIncomplete = true,
			})
		elseif method == "completionItem/resolve" then
			-- vim.print(params)
			-- -- local input = string.sub(params.context.cursor_before_line, params.offset)
			-- -- local results = vim.fn["vim_dadbod_completion#omni"](0, input)
			-- -- local items = {}
			-- -- for _, item in ipairs(results) do
			-- -- 	table.insert(items, {
			-- -- 		label = item.abbr,
			-- -- 		dup = 0,
			-- -- 		insertText = item.word,
			-- -- 		labelDetails = {
			-- -- 			description = item.menu,
			-- -- 		},
			-- -- 		documentation = item.info,
			-- -- 		kind = map_kind_to_cmp_lsp_kind[item.kind],
			-- -- 	})
			-- -- end
			-- --
			callback(nil, params)
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
	vim.lsp.config["dadbod"] = {
		cmd = cmd_fn,
		filetypes = { "sql", "dadbod" },
		root_dir = function(bufnr, on_dir)
			on_dir(vim.fn.getcwd())
		end,
	}
	vim.lsp.enable("dadbod")
end

return M
