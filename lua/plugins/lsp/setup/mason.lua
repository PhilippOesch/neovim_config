local utils = require("utils")

require("mason").setup()

local vue_language_server_path = vim.fn.expand("$MASON/packages")
	.. "/vue-language-server"
	.. "/node_modules/@vue/language-server"
-- or even
local vue_plugin = {
	name = "@vue/typescript-plugin",
	location = vue_language_server_path,
	languages = { "vue" },
	configNamespace = "typescript",
}

-- Enable the following language servers
local servers = {
	html = {
		filetypes = { "html", "twig", "hbs", "tsx" },
	},
	gopls = {},
	angularls = {},
	sqlls = {},
	jdtls = {},
	golangci_lint_ls = {},
	vue_ls = {},
	vtsls = {
		settings = {
			vtsls = {
				tsserver = {
					globalPlugins = {
						vue_plugin,
					},
				},
			},
		},
		filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
	},
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

local excludedSetups = { "jdtls", "vue_ls", "angularls", "copilot" }

mason_lspconfig.setup({
	ensure_installed = vim.tbl_keys(servers or {}),
	automatic_installation = false,
	automatic_enable = false,
})

local config_servers = function()
	for server_name, server in pairs(servers) do
		if not vim.tbl_contains(excludedSetups, server_name) then
			vim.lsp.config(server_name, server)
			vim.lsp.enable(server_name)
		end
	end
end

config_servers()

local custom_setups = utils.requireAll("plugins.lsp.custom_setup")

for _, s in pairs(custom_setups) do
	s.init()
end
