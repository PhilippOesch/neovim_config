local config = require("codecompanion.config")

---@class CodeCompanion.Extension
---@field setup fun(opts: table) Function called when extension is loaded
---@field exports? table Functions exposed via codecompanion.extensions.your_extension
local Extension = {}

---Setup the extension
---@param opts table Configuration options
function Extension.setup(opts)
	config.config.interactions.chat.tools["problems"] = {
		callback = "codecompanion._extensions.i_got_to_have_my_tools.problems",
		description = "Get potential issues detected by the language server",
	}
end

-- Optional: Functions exposed via codecompanion.extensions.your_extension
Extension.exports = {}

return Extension
