local cc_available, codecompanion = pcall(require, "codecompanion")
local utils = require("heirline.utils")

local list_chats_available, list_chats = pcall(require, "codecompanion._extensions.list_chats")

local Title = {
	condition = function()
		return cc_available and vim.bo.filetype == "codecompanion"
	end,
	hl = { fg = "blue", bold = true, force = true },
	provider = function(self)
		return string.format("✨CodeCompanion")
	end,
}

local TokensWithWindow = {
	condition = function()
		local buf = vim.api.nvim_get_current_buf()
		return buf
			and _G.codecompanion_chat_metadata
			and _G.codecompanion_chat_metadata[buf]
			and _G.codecompanion_chat_metadata[buf].adapter
			and _G.codecompanion_chat_metadata[buf].adapter.model_info
			and _G.codecompanion_chat_metadata[buf].adapter.model_info.limits
			and _G.codecompanion_chat_metadata[buf].adapter.model_info.limits.max_context_window_tokens
	end,
	init = function(self)
		local buf = vim.api.nvim_get_current_buf()
		local chat_metadata = _G.codecompanion_chat_metadata[buf]
		local model_info = chat_metadata.adapter.model_info

		self.tokenWindow = model_info.limits.max_context_window_tokens
		self.tokens = chat_metadata.tokens
		if self.tokenWindow then
			self.token_percentage = tonumber(math.floor(((self.tokens or 0) / (self.tokenWindow or 0)) * 100)) or 0
		else
			self.token_percentage = 0
		end
	end,
	{
		provider = function(self)
			return string.format("Context Window: %d/%d", self.tokens or 0, self.tokenWindow)
		end,
	},
	{
		provider = " ",
	},
	utils.surround({ "(", ")" }, nil, {
		{
			condition = function(self)
				return self.token_percentage
			end,
			provider = function(self)
				return self.token_percentage .. "%%"
			end,
			hl = function(self)
				if self.token_percentage <= 30 then
					return { fg = "green", bold = true }
				elseif self.token_percentage <= 65 then
					return { fg = "yellow", bold = true }
				else
					return { fg = "red", bold = true }
				end
			end,
		},
	}),
}

local TokensWithoutWindow = {
	provider = function(self)
		return string.format("Tokens: %s", self.tokens)
	end,
}

local Tokens = {
	update = {
		"User",
		pattern = "CodeCompanion*",
		callback = function()
			vim.cmd("redrawstatus")
		end,
	},
	init = function(self)
		local buf = vim.api.nvim_get_current_buf()
		self.tokens = _G.codecompanion_chat_metadata[buf].tokens
	end,
	condition = function()
		local buf = vim.api.nvim_get_current_buf()
		return buf and _G.codecompanion_chat_metadata and _G.codecompanion_chat_metadata[buf]
	end,
	fallthrough = false,
	TokensWithWindow,
	TokensWithoutWindow,
}

local adapter_icon_mapping = {
	Copilot = "",
}

local Billing = {
	init = function(self)
		local buf = vim.api.nvim_get_current_buf()
		self.billing = _G.codecompanion_chat_metadata[buf].adapter.model_info.billing
	end,
	condition = function()
		local buf = vim.api.nvim_get_current_buf()
		return cc_available
			and vim.bo.filetype == "codecompanion"
			and codecompanion.last_chat()
			and buf
			and _G.codecompanion_chat_metadata
			and _G.codecompanion_chat_metadata[buf]
			and _G.codecompanion_chat_metadata[buf].adapter
			and _G.codecompanion_chat_metadata[buf].adapter.model_info
			and _G.codecompanion_chat_metadata[buf].adapter.model_info.billing
	end,
	provider = function(self)
		return string.format("Billing: %dx", self.billing.multiplier)
	end,
}

local Chat = {
	init = function(self)
		local buf = vim.api.nvim_get_current_buf()

		if buf == nil then
			return
		end

		self.chat_info = list_chats.exports.chat_info(buf)
		-- self.adapter_name = chat.adapter.formatted_name
	end,
	condition = function()
		return list_chats_available and vim.bo.filetype == "codecompanion"
		-- return cc_available and vim.bo.filetype == "codecompanion" and codecompanion.last_chat()
	end,
	provider = function(self)
		return self.chat_info
		-- local web_icons_available, web_icons = pcall(require, "nvim-web-devicons")

		-- return "Adapter: "
	end,
}

local Adapter = {
	init = function(self)
		local chat = codecompanion.last_chat()

		self.adapter_name = chat.adapter.formatted_name
	end,
	condition = function()
		return cc_available and vim.bo.filetype == "codecompanion" and codecompanion.last_chat()
	end,
	{
		provider = function()
			local web_icons_available, web_icons = pcall(require, "nvim-web-devicons")

			return "Adapter: "
		end,
	},
	{
		provider = function(self)
			local icon = adapter_icon_mapping[self.adapter_name]

			if not icon then
				return self.adapter_name
			end

			return string.format("%s %s", icon, self.adapter_name)
		end,
		hl = {
			fg = "cyan",
		},
	},
}

local Model = {
	init = function(self)
		local buf = vim.api.nvim_get_current_buf()
		self.model = _G.codecompanion_chat_metadata[buf].adapter.model
	end,
	condition = function()
		local buf = vim.api.nvim_get_current_buf()
		return cc_available
			and vim.bo.filetype == "codecompanion"
			and codecompanion.last_chat()
			and _G.codecompanion_chat_metadata
			and _G.codecompanion_chat_metadata[buf]
			and _G.codecompanion_chat_metadata[buf].adapter
			and _G.codecompanion_chat_metadata[buf].adapter.model
	end,
	{
		provider = "Model: ",
	},
	{
		provider = function(self)
			return self.model
		end,
		hl = {
			fg = "cyan",
		},
	},
}

local Status = {
	condition = function()
		return cc_available and codecompanion.last_chat() and vim.bo.filetype == "codecompanion"
	end,
	Tokens,
}

return {
	Title = Title,
	Model = Model,
	Adapter = Adapter,
	Status = Status,
	Billing = Billing,
	Chat = Chat,
}
