vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local build_scripts = {
	["blink.cmp"] = {
		kind = { "install", "update" },
		callback = function(ev) end,
	},
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
		vim.print("script", ev, script)
		if script and vim.tbl_contains(script.kind, ev.data.kind) then
			script.callback(ev)
		end
	end,
})

-- essential
vim.pack.add({
	"https://github.com/tpope/vim-fugitive",
	"https://github.com/tpope/vim-rhubarb",
	"https://github.com/tpope/vim-sleuth",
	"https://github.com/nvim-lua/plenary.nvim",
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
require("plugins.persisted_nvim")
require("plugins.dadbod")
require("plugins.diff")
require("plugins.dooing")
require("plugins.harpoon")
require("plugins.gitsigns")
require("plugins.kulala")
require("plugins.navic")
require("plugins.markdown_preview")
require("plugins.markdown_render")
require("plugins.strudel")
require("plugins.neotest")
require("plugins.dap.init")
require("plugins.heirline.init")
