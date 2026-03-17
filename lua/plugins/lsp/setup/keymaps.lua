local utils = require("plugins.lsp.utils")

local M = {}

--- rename that unducks angular lsp rename.
local rename = function()
	if utils.is_client_active("angularls") then
		vim.lsp.buf.rename(nil, { name = "angularls" })
	else
		vim.lsp.buf.rename(nil, {})
	end
end

---@param event table attach event
function M.init(event)
	local map = function(keys, func, desc, mode)
		mode = mode or "n"
		vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
	end

	map("<leader>rn", function()
		rename()
	end, "[R]e[n]ame")
	map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x", "v" })

	local win_opts = { border = "rounded" }

	-- See `:help K` for why this keymap
	map("K", function()
		vim.lsp.buf.hover(win_opts)
	end, "Hover Documentation")
	map("<leader>k", function()
		vim.lsp.buf.signature_help(win_opts)
	end, "Signature Documentation")

	-- Lesser used LSP functionality
	map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	map("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
	map("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
	map("<leader>wl", function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, "[W]orkspace [L]ist Folders")

	local client = vim.lsp.get_client_by_id(event.data.client_id)

	-- angular specific
	if client and client.name == "angularls" then
		map("<leader>ran", function()
			vim.lsp.buf.rename(nil, { name = "angularls" })
		end, "Rename Angular")
	end

	-- The following code creates a keymap to toggle inlay hints in your
	-- code, if the language server you are using supports them
	--
	-- This may be unwanted, since they displace some of your code
	if client and utils.client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
		map("<leader>th", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
		end, "[T]oggle Inlay [H]ints")
	end
end

return M
