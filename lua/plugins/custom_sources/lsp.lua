---@class custom_sources.Source
---@field name string
---@field get_completions fun(params: lsp.CompletionParams, context: table): lsp.CompletionItem[]
---@field resolve? fun(item: lsp.CompletionItem): lsp.CompletionItem

local M = {}

---@param active_sources custom_sources.Source[]
---@param trigger_chars string[]
---@return custom_sources.lsp_server.definition
function M.create_server_def(active_sources, trigger_chars)
	return {
		onInitialize = function(_, callback)
			callback(nil, {
				capabilities = {
					completionProvider = {
						triggerCharacters = trigger_chars,
						resolveProvider = true,
					},
				},
			})
		end,
		shutdown = function(_, callback)
			callback(nil, nil)
		end,
		onCompletionItemResolve = function(_, params, callback)
			local item = params
			if item.data and item.data._source_id then
				for _, source in ipairs(active_sources) do
					if source.name == item.data._source_id and source.resolve then
						item = source.resolve(item)
						break
					end
				end
			end
			callback(nil, item)
		end,
		onTextDocumentCompletion = function(_, params, callback)
			local file_path = params.textDocument.uri:gsub("^file://", "")
			local bufnr = vim.fn.bufnr(file_path)
			if bufnr == -1 then
				bufnr = 0
			end

			local line = vim.api.nvim_buf_get_lines(bufnr, params.position.line, params.position.line + 1, false)[1] or ""
			local line_to_cursor = line:sub(1, params.position.character)
			local context = {
				bufnr = bufnr,
				line = line,
				line_to_cursor = line_to_cursor,
			}

			local all_items = {}

			for _, source in ipairs(active_sources) do
				local ok, items = pcall(source.get_completions, params, context)
				if not ok then
					vim.notify(
						"[custom_sources] Source '" .. source.name .. "' failed: " .. tostring(items),
						vim.log.levels.ERROR
					)
				else
					for _, item in ipairs(items) do
						item.data = item.data or {}
						item.data._source_id = source.name
						table.insert(all_items, item)
					end
				end
			end

			callback(nil, {
				items = all_items,
				isIncomplete = false,
			})
		end,
	}
end

return M
