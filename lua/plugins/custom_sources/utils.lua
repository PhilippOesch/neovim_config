---@alias custom_sources.lsp_server.definition.onCompletionItemResolveCb fun(error?: lsp.ResponseError, result: lsp.CompletionItem)
---@alias custom_sources.lsp_server.definition.onTextDocumentCompletionCb fun(error?: lsp.ResponseError, result: vim.lsp.CompletionResult)
---
---@class custom_sources.lsp_server: custom_sources.lsp_server.definition
---@field dispatchers vim.lsp.rpc.Dispatchers
---@field request_id integer
---@field server vim.lsp.rpc.PublicClient

---@class custom_sources.lsp_server.definition
---@field onInitialize? fun(self:custom_sources.lsp_server, callback: any)
---@field onTextDocumentCompletion? fun(self:custom_sources.lsp_server, params: lsp.CompletionParams, callback: custom_sources.lsp_server.definition.onTextDocumentCompletionCb)
---@field onCompletionItemResolve? fun(self:custom_sources.lsp_server, params: lsp.CompletionItem, callback: custom_sources.lsp_server.definition.onCompletionItemResolveCb)
---@field shutdown? fun(self:custom_sources.lsp_server, callback: any)

local Utils = {}

---comment
---@param definition custom_sources.lsp_server.definition
---@return fun(dispatcher: vim.lsp.rpc.Dispatchers ): vim.lsp.rpc.PublicClient
function Utils.create_lsp(definition)
	return function(dispatchers)
		local lsp_server = {
			closing = false,
			request_id = 0,
			server = {},
		}

		lsp_server = vim.tbl_deep_extend("force", lsp_server, definition)

		---@type vim.lsp.rpc.PublicClient
		local rpcClient = {}

		function rpcClient.request(method, params, callback)
			if method == "initialize" then
				if lsp_server.onInitialize then
					lsp_server.onInitialize(lsp_server, callback)
				end
			elseif method == "shutdown" then
				if lsp_server.shutdown then
					lsp_server.shutdown(lsp_server, callback)
				end
			elseif method == "textDocument/completion" then
				if lsp_server.onTextDocumentCompletion then
					lsp_server.onTextDocumentCompletion(lsp_server, params, callback)
				end
			elseif method == "completionItem/resolve" then
				if lsp_server.onCompletionItemResolve then
					lsp_server.onCompletionItemResolve(lsp_server, params, callback)
				end
			end
			lsp_server.request_id = lsp_server.request_id + 1

			return true, lsp_server.request_id
		end

		function rpcClient.notify(method, params)
			if method == "exit" then
				dispatchers.on_exit(0, 15)
			end
		end

		function rpcClient.is_closing()
			return closing
		end

		function rpcClient.terminate()
			closing = true
		end

		return rpcClient
	end
end

return Utils
