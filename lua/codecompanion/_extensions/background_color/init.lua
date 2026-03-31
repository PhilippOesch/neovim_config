local M = {}

local Extension = {
	opts = {},
}

function Extension.setup(opts)
	vim.api.nvim_clear_autocmds({
		pattern = "*.codecompanion",
		group = vim.api.nvim_create_augroup("CodeCompanionBackground", { clear = true }),
	})

	vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
		group = "CodeCompanionBackground",
		callback = function()
			if vim.bo.filetype ~= nil and vim.bo.filetype == "codecompanion" then
				vim.wo.winhighlight = "Normal:NormalFloat"
			else
				vim.wo.winhighlight = "Normal:Normal"
			end
		end,
	})
end

return Extension
