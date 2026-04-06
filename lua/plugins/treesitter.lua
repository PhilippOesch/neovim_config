vim.pack.add({
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
	"https://github.com/nvim-treesitter/nvim-treesitter-context",
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
		version = "main",
	},
}, { confirm = false })

vim.cmd.packadd("nvim-treesitter")

local treesitter = require('nvim-treesitter')

treesitter.setup({})

local ensureInstalled = {
	"c",
	"cpp",
	"java",
	"json",
	"scss",
	"css",
	"lua",
	"diff",
	"python",
	"rust",
	"tsx",
	"jsx",
	"javascript",
	"typescript",
	"jsdoc",
	"vimdoc",
	"vim",
	"bash",
	"xml",
	"yaml",
	"c_sharp",
	"vue",
	"angular",
	"go",
}

if vim.fn.executable("tree-sitter") == 1 then
	vim.defer_fn(function()
		require("nvim-treesitter").install(ensureInstalled)
	end, 2000)
else
	local msg = "`tree-sitter-cli` not found. Skipping auto-install of parsers."
	vim.notify(msg, vim.log.levels.WARN, { title = "Treesitter" })
end

-- require("nvim-treesitter").update()

-- auto-start highlights & indentation
vim.api.nvim_create_autocmd("FileType", {
	desc = "User: enable treesitter highlighting",
	callback = function(ctx)
		-- highlights
		local hasStarted = pcall(vim.treesitter.start, ctx.buf) -- errors for filetypes with no parser

		-- indent
		local dontUseTreesitterIndent = { "zsh", "bash", "markdown", "javascript" }
		if hasStarted and not vim.list_contains(dontUseTreesitterIndent, ctx.match) then
			vim.bo[ctx.buf].indentexpr = "v:lua.require('nvim-treesitter').indentexpr()"
		end
	end,
})

-- comments parser
vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
	desc = "User: highlights for the Treesitter `comments` parser",
	callback = function()
		-- FIX todo-comments in languages where LSP overwrites their highlight
		-- https://github.com/stsewd/tree-sitter-comment/issues/22
		-- https://github.com/LuaLS/lua-language-server/issues/1809
		vim.api.nvim_set_hl(0, "@lsp.type.comment", {})

		-- Define `@comment.bold` for `queries/comment/highlights.scm`
		vim.api.nvim_set_hl(0, "@comment.bold", { bold = true })
	end,
})

require("nvim-treesitter-textobjects").setup({
	textobjects = {
		select = {
			enable = true,
			lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
			keymaps = {
				-- You can use the capture groups defined in textobjects.scm
				["aa"] = "@parameter.outer",
				["ia"] = "@parameter.inner",
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
			},
		},
		move = {
			enable = true,
			set_jumps = true, -- whether to set jumps in the jumplist
			goto_next_start = {
				["]m"] = "@function.outer",
				["]]"] = "@class.outer",
			},
			goto_next_end = {
				["]M"] = "@function.outer",
				["]["] = "@class.outer",
			},
			goto_previous_start = {
				["[m"] = "@function.outer",
				["[["] = "@class.outer",
			},
			goto_previous_end = {
				["[M"] = "@function.outer",
				["[]"] = "@class.outer",
			},
		},
		swap = {
			enable = true,
			swap_next = {
				["<leader>pa"] = "@parameter.inner",
			},
			swap_previous = {
				["<leader>pA"] = "@parameter.inner",
			},
		},
	},
})
