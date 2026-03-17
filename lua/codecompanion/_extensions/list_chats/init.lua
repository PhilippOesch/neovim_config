local config = require("codecompanion.config")

---@class CodeCompanion.Extension
---@field setup fun(opts: table) Function called when extension is loaded
---@field exports? table Functions exposed via codecompanion.extensions.your_extension
local Extension = {}

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

			return {
				title = string.format("%d", v),
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
				{ "Buf: " .. item.title },
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
