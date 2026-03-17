local buffer_slash_command = require("codecompanion.interactions.chat.slash_commands.builtin.buffer")
local config = require("codecompanion.config")
local strategies = require("codecompanion.interactions")
local codecompanion = require("codecompanion")

local Extension = {
	enabled = true,
	opts = {
		excluded_filetypes = { "codecompanion" },
	},
}

local get_ref_id = function(path)
	-- see: https://github.com/olimorris/codecompanion.nvim/blob/main/lua/codecompanion/utils/buffers.lua
	local relative_path = vim.fn.fnamemodify(path, ":.")
	return "<buf>" .. relative_path .. "</buf>"
end

Extension.exports = {
	add_current_buffer_to_chat = function()
		local bufnr = vim.api.nvim_get_current_buf()
		local abs_path = vim.api.nvim_buf_get_name(bufnr)
		local filetype = vim.bo[bufnr].filetype

		if vim.tbl_contains(Extension.opts.excluded_filetypes, filetype) then
			vim.notify("Can not add " .. filetype .. " files", vim.log.levels.INFO)
			return
		end

		local chat = codecompanion.last_chat()
		if not chat then
			chat = codecompanion.chat()
		end
		chat.ui:open({ toggled = true })

		if not chat then
			return
		end
		--
		local buffer_slash = buffer_slash_command.new({
			Chat = chat,
			config = config.interactions.chat.slash_commands["buffer"],
			context = chat.context,
		})

		local abs_path = vim.api.nvim_buf_get_name(bufnr)
		local id = get_ref_id(abs_path)
		local currentReferences = chat.context:get_from_chat()

		if not vim.tbl_contains(currentReferences, id) then
			local selectedItem = {
				bufnr = bufnr,
				path = abs_path,
			}
			buffer_slash:output(selectedItem)
		end
	end,

	add_open_buffer_to_chat = function()
		local chat = codecompanion.last_chat()
		if not chat then
			chat = codecompanion.chat()
		end
		chat.ui:open({ toggled = true })

		local slash_commands = config.interactions.chat.slash_commands

		if not chat then
			return
		end

		local buffer_slash = buffer_slash_command.new({
			Chat = chat,
			config = config.interactions.chat.slash_commands["buffer"],
			context = chat.context,
		})

		local currentReferences = chat.context:get_from_chat()

		for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
			local filetype = vim.bo[bufnr].filetype

			if
				not vim.tbl_contains(Extension.opts.excluded_filetypes, filetype)
				and filetype ~= "nofile"
				and vim.bo[bufnr].buflisted
			then
				local abs_path = vim.api.nvim_buf_get_name(bufnr)

				local id = get_ref_id(abs_path)

				if not vim.tbl_contains(currentReferences, id) then
					local selectedItem = {
						bufnr = bufnr,
						path = abs_path,
					}
					buffer_slash:output(selectedItem)
				end
			end
		end
	end,
}
function Extension.setup(opts)
	if opts ~= nil then
		Extension.opts = vim.tbl_extend("force", Extension.opts, opts)
	end

	vim.keymap.set("n", "<leader>ib", Extension.exports.add_current_buffer_to_chat, {
		noremap = true,
		desc = "Add buffer to codecompanion chat",
	})
	vim.keymap.set("n", "<leader>iB", Extension.exports.add_open_buffer_to_chat, {
		noremap = true,
		desc = "Add open buffers to codecompanion chat",
	})

	local ok, wk = pcall(require, "which-key")

	if ok then
		wk.add({
			{ "<leader>ib", icon = "✨" },
			{ "<leader>iB", icon = "✨" },
		})
	end
end

return Extension
