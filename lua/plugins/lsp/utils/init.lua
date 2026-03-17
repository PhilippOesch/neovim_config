local M = {}

local disable_mapping = {
	marksman = {
		"$HOME/Documents/ObsidianVault/",
	},
}

local active_typescript_lsp = "typescript-tools"

---comment
---@param client_name string
---@return boolean
M.is_client_active = function(client_name)
	return vim.tbl_contains(vim.lsp.get_clients(), function(client)
		return client.name == client_name
	end, { predicate = true })
end

--- some lsps are so terrible they need handholding ( *cough cough* angular)
---@type table<string,table<string, lsp.Handler>>
local customHandlers = {
	["angularls"] = {
		["textDocument/rename"] = function(_, result, ctx)
			if not result then
				-- use typescript language server instead for renaming
				vim.lsp.buf.rename(ctx.params.newName, { name = "typescript-tools" })
				return
			end
			local res = vim.lsp.handlers["textDocument/rename"](_, result, ctx)
		end,
	},
}

M.manage_ts_ls_angular_compatibility = function(event, client)
	local is_ts_ls_active = M.is_client_active(active_typescript_lsp)
	if client and is_ts_ls_active and client.name == "angularls" then
		local ts_ls = M.get_client_by_name(active_typescript_lsp)
		ts_ls.server_capabilities.referencesProvider = false
	elseif client and M.is_client_active("angularls") and client.name == active_typescript_lsp then
		client.server_capabilities.referencesProvider = false
	end
end

-- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
---@param client vim.lsp.Client
---@param method vim.lsp.protocol.Method
---@param bufnr? integer some lsp support methods only in specific files
---@return boolean
function M.client_supports_method(client, method, bufnr)
	if vim.fn.has("nvim-0.11") == 1 then
		return client:supports_method(method, bufnr or 0)
	else
		return client.supports_method(method, { bufnr = bufnr or 0 })
	end
end

M.get_client_by_name = function(client_name)
	for _, client in ipairs(vim.lsp.get_clients()) do
		if client.name == client_name then
			return client
		end
	end
	return nil
end

M.on_attach = function(event)
	local keymaps = require("plugins.lsp.setup.keymaps")

	local ok, navic = pcall(require, "nvim-navic")

	keymaps.init(event)

	local client = vim.lsp.get_client_by_id(event.data.client_id)

	if ok and client.server_capabilities.documentSymbolProvider then
		navic.attach(client, event.buf)
	end

	if disable_mapping[client.name] ~= nil and client.root_dir ~= nil then
		local paths = vim.iter(disable_mapping[client.name])
			:map(function(path)
				vim.fs.normalize(vim.fn.expand(path))
			end)
			:totable()

		if vim.tbl_contains(paths, client.root_dir) then
			vim.lsp.enable(client.name, false)
		end
		return
	end

	if client and customHandlers[client.name] then
		client.handlers = vim.tbl_deep_extend("force", client.handlers or {}, customHandlers[client.name])
	end

	-- Diagnostic Config
	-- See :help vim.diagnostic.Opts
	vim.diagnostic.config({
		severity_sort = true,
		float = { border = "rounded", source = "if_many" },
		underline = { severity = vim.diagnostic.severity.ERROR },
		signs = vim.g.have_nerd_font and {
			text = {
				[vim.diagnostic.severity.ERROR] = "󰅚 ",
				[vim.diagnostic.severity.WARN] = "󰀪 ",
				[vim.diagnostic.severity.INFO] = "󰋽 ",
				[vim.diagnostic.severity.HINT] = "󰌶 ",
			},
		} or {},
		virtual_text = {
			source = "if_many",
			spacing = 2,
			format = function(diagnostic)
				local diagnostic_message = {
					[vim.diagnostic.severity.ERROR] = diagnostic.message,
					[vim.diagnostic.severity.WARN] = diagnostic.message,
					[vim.diagnostic.severity.INFO] = diagnostic.message,
					[vim.diagnostic.severity.HINT] = diagnostic.message,
				}
				return diagnostic_message[diagnostic.severity]
			end,
		},
	})

	M.manage_ts_ls_angular_compatibility(event, client)

	if
		client and M.client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
	then
		local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
			buffer = event.buf,
			group = highlight_augroup,
			callback = vim.lsp.buf.document_highlight,
		})

		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
			buffer = event.buf,
			group = highlight_augroup,
			callback = vim.lsp.buf.clear_references,
		})

		vim.api.nvim_create_autocmd("LspDetach", {
			group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
			callback = function(event2)
				vim.lsp.buf.clear_references()
				vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
			end,
		})
	end
end

-- local capabilities = vim.lsp.protocol.make_client_capabilities()
-- capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
local capabilities = require("blink-cmp").get_lsp_capabilities()

M.capabilities = capabilities

return M
