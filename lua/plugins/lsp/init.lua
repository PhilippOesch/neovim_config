---@type Config.Plugin
return {
	deps = {
		"https://github.com/pmizio/typescript-tools.nvim",
		"https://github.com/neovim/nvim-lspconfig",
		"https://github.com/williamboman/mason.nvim",
		"https://github.com/williamboman/mason-lspconfig.nvim",
		"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
		"https://github.com/ionide/Ionide-vim",
		"https://github.com/mfussenegger/nvim-jdtls",
		"https://github.com/folke/lazydev.nvim",
		"https://github.com/seblj/roslyn.nvim",
	},
	init = function()
		local lspHelpers = require("plugins.lsp.utils")

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),

			callback = function(event)
				-- schematic templates contain `<% %>` tags, so they are not valid TS/HTML
				if vim.api.nvim_buf_get_name(event.buf):match("%.template$") then
					vim.schedule(function()
						vim.lsp.buf_detach_client(event.buf, event.data.client_id)
					end)
					return
				end
				lspHelpers.on_attach(event)
			end,
		})

		local lsp_log_path = vim.fn.stdpath("state") .. "/lsp.log"
		vim.api.nvim_create_user_command("LspLog", "tabe " .. lsp_log_path, { desc = "open lsp logs" })

		require("plugins.lsp.setup.mason")
	end,
}
