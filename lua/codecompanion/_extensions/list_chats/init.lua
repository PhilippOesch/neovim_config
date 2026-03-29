local config = require("codecompanion.config")

---@class CodeCompanion.Extension
---@field setup fun(opts: table) Function called when extension is loaded
---@field exports? table Functions exposed via codecompanion.extensions.your_extension
local Extension = {}

---comment
---@param title string|nil
---@param max_length number
---@return string
local function truncateText(title, max_length)
	if title ~= nil then
		local title_str = tostring(title)
		-- use vim.fn.strchars/strcharpart to handle multibyte characters if available
		if vim and vim.fn and vim.fn.strchars then
			if vim.fn.strchars(title_str) > max_length then
				return vim.fn.strcharpart(title_str, 0, max_length) .. "…"
			else
				return title_str
			end
		else
			if #title_str > max_length then
				return title_str:sub(1, max_length) .. "…"
			else
				return title_str
			end
		end
	end
	return ""
end

local function open_chat_picker()
	local ok, snacks = pcall(require, "snacks")

	if not ok then
		vim.notify("Snacks has to be installed.", vim.log.levels.WARN)
		return
	end

	local cc_available, codecompanion = pcall(require, "codecompanion.interactions.chat")

	if not cc_available then
		vim.notify("Codecompanoin is not available", vim.log.levels.WARN)
		return
	end

	if not _G.codecompanion_buffers then
		vim.notify("No open codecompanion chats", vim.log.levels.WARN)
		return
	end

	-- vim.print(_G.codecompanion_buffers)

	local items = vim.iter(ipairs(_G.codecompanion_buffers))
		:map(function(i, v)
			local info = _G.codecompanion_chat_metadata[v]

			local generate_title = require("codecompanion").buf_get_chat(v)
				and require("codecompanion").buf_get_chat(v).title

			return {
				title = string.format("%d", v),
				gen_title = truncateText(generate_title, 30),
				text = string.format("%d %s %s %d", v, (info.adapter).name, (info.adapter).model, info.tokens),
				buf = v,
				index = i,
				adapter = info.adapter and (info.adapter).name,
				model = info.adapter and (info.adapter).model,
				tokens = info.tokens,
			}
		end)
		:totable()

	snacks.picker({
		items = items,
		format = function(item, _)
			local formatted = {
				{ item.index .. ". ", "Constant" },
				{ " " .. item.gen_title },
				{ " - " },
				{ item.adapter, "Special" },
				{ " (" .. item.model .. ")", "Special" },
				{ string.format(" - Tokens: %d", item.tokens) },
			}
			return formatted
		end,
	})
end

local function index_of(tbl, value)
	for i, v in ipairs(tbl) do
		if v == value then
			return i
		end
	end
	return nil
end

local function chat_index(buf)
	if not buf or not _G.codecompanion_buffers then
		return nil
	end
	local n = #_G.codecompanion_buffers
	local i = index_of(_G.codecompanion_buffers, buf)
	if not i then
		return nil
	end
	return string.format("Chat: %d of %d", i, n)
end

-- Optional: Functions exposed via codecompanion.extensions.your_extension
Extension.exports = {
	open_chat_picker = open_chat_picker,
	chat_info = chat_index,
}

---Setup the extension
---@param opts table Configuration options
function Extension.setup(opts)
	vim.keymap.set({ "n" }, "<leader>il", Extension.exports.open_chat_picker, {
		noremap = true,
		desc = "list open chats",
	})

	local ok, wk = pcall(require, "which-key")

	if ok then
		wk.add({
			{ "<leader>il", icon = "✨" },
		})
	end
end

return Extension
