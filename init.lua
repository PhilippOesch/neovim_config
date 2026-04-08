vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local build_scripts = {
	["strudel.nvim"] = {
		kind = { "install", "update" },
		callback = function(ev)
			vim.fn.system("cd " .. ev.data.path .. " && npm ci")
		end,
	},
	["nvim-treesitter"] = {
		kind = { "install", "update" },
		callback = function(ev)
			if not ev.data.active then
				vim.cmd.packadd("nvim-treesitter")
			end
			vim.cmd("TSUpdate")
		end,
	},
	["markdown-preview.nvim"] = {
		kind = { "install", "update" },
		callback = function(ev)
			vim.fn.system("cd " .. ev.data.path .. " && cd app && yarn install")
		end,
	},
	["vscode-js-debug"] = {
		kind = { "install", "update" },
		callback = function(ev)
			vim.fn.system("cd " .. ev.data.path .. " && npm i && npm run compile vsDebugServerBundle && mv dist out")
		end,
	},
}

vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local script = build_scripts[ev.data.spec.name]
		if script and vim.tbl_contains(script.kind, ev.data.kind) then
			script.callback(ev)
		end
	end,
})

vim.pack.add({
	"https://github.com/tpope/vim-fugitive",
	"https://github.com/tpope/vim-rhubarb",
	"https://github.com/tpope/vim-sleuth",
	"https://github.com/nvim-lua/plenary.nvim",
	{ src = "https://github.com/saghen/blink.cmp", version = "v1.10.2" },
	"https://github.com/L3MON4D3/LuaSnip",
	"https://github.com/rafamadriz/friendly-snippets",
	"https://github.com/numToStr/Comment.nvim",
	"https://github.com/JoosepAlviste/nvim-ts-context-commentstring",
	"https://github.com/stevearc/conform.nvim",
	"https://github.com/tpope/vim-dadbod",
	"https://github.com/kristijanhusak/vim-dadbod-ui",
	"https://github.com/kristijanhusak/vim-dadbod-completion",
	"https://github.com/esmuellert/vscode-diff.nvim",
	"https://github.com/MunifTanjim/nui.nvim",
	"https://github.com/atiladefreitas/dooing",
	"https://github.com/lewis6991/gitsigns.nvim",
	"https://github.com/ThePrimeagen/harpoon",
	"https://github.com/mistweaverco/kulala.nvim",
	"https://github.com/iamcco/markdown-preview.nvim",
	"https://github.com/MeanderingProgrammer/render-markdown.nvim",
	"https://github.com/SmiteshP/nvim-navic",
	"https://github.com/nvim-neotest/neotest",
	"https://github.com/nvim-neotest/nvim-nio",
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/antoinemadec/FixCursorHold.nvim",
	"https://github.com/haydenmeade/neotest-jest",
	"https://github.com/Nsidorenco/neotest-vstest",
	"https://github.com/rcasia/neotest-java",
	"https://github.com/nvim-neotest/neotest-go",
	"https://github.com/marilari88/neotest-vitest",
	"https://github.com/norcalli/nvim-colorizer.lua",
	"https://github.com/obsidian-nvim/obsidian.nvim",
	"https://github.com/stevearc/oil.nvim",
	"https://github.com/refractalize/oil-git-status.nvim",
	"https://github.com/olimorris/persisted.nvim",
	"https://github.com/sphamba/smear-cursor.nvim",
	"https://github.com/folke/snacks.nvim",
	"https://github.com/echasnovski/mini.surround",
	"https://github.com/folke/todo-comments.nvim",
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
	"https://github.com/nvim-treesitter/nvim-treesitter-context",
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
		version = "main",
	},
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/folke/which-key.nvim",
	"https://github.com/folke/tokyonight.nvim",
	"https://github.com/olimorris/codecompanion.nvim",
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/ravitemer/codecompanion-history.nvim",
	"https://github.com/zbirenbaum/copilot.lua",
	"https://github.com/j-hui/fidget.nvim",
	"https://github.com/pmizio/typescript-tools.nvim",
	"https://github.com/mfussenegger/nvim-dap",
	"https://github.com/rcarriga/nvim-dap-ui",
	"https://github.com/leoluz/nvim-dap-go",
	"https://github.com/jay-babu/mason-nvim-dap.nvim",
	{ src = "https://github.com/microsoft/vscode-js-debug", version = "v1.112.0" },
	"https://github.com/theHamsta/nvim-dap-virtual-text",
	"https://github.com/windwp/nvim-autopairs",
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/williamboman/mason.nvim",
	"https://github.com/williamboman/mason-lspconfig.nvim",
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
	"https://github.com/folke/lazydev.nvim",
	"https://github.com/ionide/Ionide-vim",
	"https://github.com/seblj/roslyn.nvim",
	"https://github.com/mfussenegger/nvim-jdtls",
	"https://github.com/gruvw/strudel.nvim",
	"https://github.com/rebelot/heirline.nvim",
}, { confirm = false })

require("config.theme")
require("config.general")
require("config.keymaps")

-- Plugins
require("plugins.blink_cmp")
require("plugins.lsp.init")
require("plugins.treesitter")
require("plugins.whichkey")
require("plugins.oil")
require("plugins.autopairs")
require("plugins.snacks")
require("plugins.webdev_icons")
require("plugins.todo_comment")
require("plugins.surround")
require("plugins.smear_nvim")
require("plugins.comment")
require("plugins.obsidian_nvim")
require("plugins.conform")
require("plugins.dadbod")
require("plugins.dooing")
require("plugins.harpoon")
require("plugins.gitsigns")
-- require("plugins.kulala")
require("plugins.navic")
require("plugins.markdown_preview")
require("plugins.markdown_render")
require("plugins.strudel")
require("plugins.neotest")
require("plugins.dap.init")
require("plugins.codecompanion.init")
require("plugins.heirline.init")
require("plugins.persisted_nvim")
