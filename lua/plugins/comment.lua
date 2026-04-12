---@type Config.Plugin
return {
	deps = {
		"https://github.com/numToStr/Comment.nvim",
		"https://github.com/JoosepAlviste/nvim-ts-context-commentstring",
	},
	init = function()
		require("Comment").setup({
			pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
		})
	end,
}
