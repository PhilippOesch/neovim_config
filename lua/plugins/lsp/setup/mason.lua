local utils = require("utils")

-- mason-lspconfig requires that these setup functions are called in this order
-- before setting up the servers.
require("mason").setup({
	registries = { "github:Crashdummyy/mason-registry", "github:mason-org/mason-registry" },
})

local vue_ls_share = vim.fn.expand("$MASON/packages/vue-language-server")
local vue_language_server_path = vue_ls_share .. "/node_modules/@vue/language-server"

-- Enable the following language servers
local servers = {
	html = {
		filetypes = { "html", "twig", "hbs", "tsx" },
	},
	gopls = {},
	angularls = {},
	-- ["angularls@19.2.4"] = {},
	sqlls = {},
	jdtls = {},
	golangci_lint_ls = {},
	vue_ls = {},
	["eslint@4.8.0"] = {},
	tailwindcss = {
		classAttributes = { "class", "className", "class:list", "classList", "ngClass", "placeholderClassName" },
		filetypes = {
			"typescript.tsx",
			"vue",
			"html",
			"htmlangular",
			"javascriptreact",
			"typescriptreact",
			"css",
			"scss",
			"sass",
		},
	},
	cssls = {},
	pyright = {},
	marksman = {},
	lua_ls = {
		Lua = {
			workspace = { checkThirdParty = false },
			telemetry = { enable = false },
			-- NOTE: toggle below to ignore Lua_LS's noisy `missing-fields` warnings
			-- diagnostics = { disable = { 'missing-fields' } },
		},
	},
}

-- Setup neovim lua configuration
require("lazydev").setup()

-- Ensure the servers above are installed
local mason_lspconfig = require("mason-lspconfig")
local mason_tool_installer = require("mason-tool-installer")

local ensure_tools_installed = {}
local other_tools = {
	"roslyn",
	"java-test",
	"golangci-lint",
	"tree-sitter-cli",
}
ensure_tools_installed = vim.list_extend(ensure_tools_installed, other_tools)
local formatters = {
	"black",
	"stylua",
	"xmlformatter",
	"prettier",
	"prettierd",
	"csharpier",
	"golines",
	"goimports",
	"markdownlint-cli2",
	"markdown-toc",
	"yamlfmt",
}
ensure_tools_installed = vim.list_extend(ensure_tools_installed, formatters)
local debuggers = {
	"delve",
	"netcoredbg",
	"js-debug-adapter",
	"java-debug-adapter",
	"firefox-debug-adapter",
}
ensure_tools_installed = vim.list_extend(ensure_tools_installed, debuggers)

mason_tool_installer.setup({
	ensure_installed = ensure_tools_installed,
})

local lspHelpers = require("plugins.lsp.utils")

local excludedSetups = { "jdtls", "vue_ls", "roslyn", "angularls", "copilot" }

mason_lspconfig.setup({
	ensure_installed = vim.tbl_keys(servers or {}),
	automatic_installation = false,
	automatic_enable = false,
})

local config_servers = function()
	for server_name, server in pairs(servers) do
		if not vim.tbl_contains(excludedSetups, server_name) then
			server.capabilities = vim.tbl_deep_extend("force", {}, lspHelpers.capabilities, server.capabilities or {})
			vim.lsp.config(server_name, server)
			vim.lsp.enable(server_name)
		end
	end
end

config_servers()

local custom_setups = utils.requireAll("plugins.lsp.custom_setup")

for ls, s in pairs(custom_setups) do
	s.init()
end
