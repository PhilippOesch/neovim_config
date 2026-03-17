local progress = require("fidget.progress")

local Extension = {
	processing = false,
	spinner_index = 1,
	namespace_id = nil,
	timer = nil,
	opts = {},
	spinner_symbols = {
		"⠋",
		"⠙",
		"⠹",
		"⠸",
		"⠼",
		"⠴",
		"⠦",
		"⠧",
		"⠇",
		"⠏",
	},
	filetype = "codecompanion",
}

function Extension:get_buf(filetype)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == filetype then
			return buf
		end
	end
	return nil
end

function Extension:update_spinner()
	if not self.processing then
		self:stop_spinner()
		return
	end

	self.spinner_index = (self.spinner_index % #self.spinner_symbols) + 1

	local buf = self:get_buf(self.filetype)
	if buf == nil then
		return
	end

	-- Clear previous virtual text
	vim.api.nvim_buf_clear_namespace(buf, self.namespace_id, 0, -1)

	local last_line = vim.api.nvim_buf_line_count(buf) - 1
	vim.api.nvim_buf_set_extmark(buf, self.namespace_id, last_line, 0, {
		virt_lines = { { { self.spinner_symbols[self.spinner_index] .. " Processing...", "Comment" } } },
		virt_lines_above = true, -- false means below the line
	})
end

function Extension:start_spinner()
	self.processing = true
	self.spinner_index = 0

	if self.timer then
		self.timer:stop()
		self.timer:close()
		self.timer = nil
	end

	self.timer = vim.loop.new_timer()
	self.timer:start(
		0,
		100,
		vim.schedule_wrap(function()
			self:update_spinner()
		end)
	)
end

function Extension:stop_spinner()
	self.processing = false

	if self.timer then
		self.timer:stop()
		self.timer:close()
		self.timer = nil
	end

	local buf = self:get_buf(self.filetype)
	if buf == nil then
		return
	end

	vim.api.nvim_buf_clear_namespace(buf, self.namespace_id, 0, -1)
end

function Extension:init()
	local init_inline_spinner = function()
		-- Create namespace for virtual text
		self.namespace_id = vim.api.nvim_create_namespace("CodeCompanionSpinner")

		vim.api.nvim_create_augroup("CodeCompanionHooks", { clear = true })
		local group = vim.api.nvim_create_augroup("CodeCompanionHooks", {})

		vim.api.nvim_create_autocmd({ "User" }, {
			pattern = "CodeCompanionRequest*",
			group = group,
			callback = function(request)
				if request.match == "CodeCompanionRequestStarted" then
					self:start_spinner()
				elseif request.match == "CodeCompanionRequestFinished" then
					self:stop_spinner()
				end
			end,
		})
	end

	local init_notifier = function()
		local group = vim.api.nvim_create_augroup("CodeCompanionFidgetHooks", { clear = true })
		vim.api.nvim_create_autocmd({ "User" }, {
			pattern = "CodeCompanionRequest*",
			group = group,
			callback = function(request)
				local msg

				if vim.startswith(request.match, "CodeCompanionRequestStarted") then
					msg = "[CodeCompanion] starting..."
				elseif request.match == "CodeCompanionRequestStreaming" then
					msg = "[CodeCompanion] streaming..."
				else
					msg = "[CodeCompanion] finished"
				end

				vim.notify(msg, "info", {
					id = "code_companion_status",
					title = "Code Companion Status",
					opts = function(notif)
						notif.icon = vim.startswith(request.match, "CodeCompanionRequestFinished") and " "
							---@diagnostic disable-next-line: undefined-field
							or Extension.spinner_symbols[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #Extension.spinner_symbols + 1]
					end,
				})
			end,
		})
	end

	init_notifier()
	init_inline_spinner()
end

function Extension.setup()
	Extension:init()
end

return Extension
