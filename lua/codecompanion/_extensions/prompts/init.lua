local path = require("plenary.path")
local config = require("codecompanion.config")

---@class CodeCompanion._extensions.BeastMode.Exports
---@field get_prompt fun():string

---@class CodeCompanion._extensions.BeastMode
---@field setup fun(opts: table) Function called when extension is loaded
---@field exports? CodeCompanion._extensions.BeastMode.Exports Functions exposed via codecompanion.extensions.your_extension
local Extension = {
	cached = {},
	base_path = "",
}

local function get_prompt(fileName)
	local filePath = Extension.base_path .. fileName

	if Extension.cached[filePath] ~= nil then
		return Extension.cached[filePath]
	end

	local ok, content = pcall(function()
		return path.new(filePath):read()
	end)

	Extension.cached = content

	if not ok then
		vim.notify("Could not load prompt", vim.log.levels.ERROR)
		return ""
	end

	return content
end

---Setup the extension
---@param opts table Configuration options
function Extension.setup(opts)
	Extension.base_path = opts.base_path or vim.fn.stdpath("config") .. "/lua/codecompanion/_extensions/prompts/lib/"

	config.config.prompt_library["Beast Mode"] = {
		strategy = "chat",
		description = "Use 'Beast Mode' (see github gist) Base Prompt",
		opts = {
			index = 5,
			is_slash_cmd = true,
			ignore_system_prompt = false,
			auto_submit = false,
			alias = "beast_mode",
		},
		context = {
			{
				type = "file",
				path = {
					".github/copilot-instructions.md",
				},
			},
		},
		prompts = {
			{
				role = "user",
				content = "use @{full_stack_dev}",
			},
			{
				role = "user",
				content = function()
					return get_prompt("beast_mode.md")
				end,
				opts = {
					visible = true,
				},
			},
		},
	}
	config.config.prompt_library["Gilfoyle"] = {
		strategy = "chat",
		description = "Code review and analysis with the sardonic wit and technical elitism of Bertram Gilfoyle from Silicon Valley. Prepare for brutal honesty about your code.",
		opts = {
			index = 15,
			is_slash_cmd = true,
			ignore_system_prompt = false,
			auto_submit = false,
			alias = "gilfoyle",
		},
		context = {
			{
				type = "file",
				path = {
					".github/copilot-instructions.md",
				},
			},
		},
		prompts = {
			{
				role = "user",
				content = "use @{reviewer}",
			},
			{
				role = "user",
				content = function()
					return get_prompt("gilfoyle.md")
				end,
				opts = {
					visible = true,
				},
			},
		},
	}
	config.config.prompt_library["Readme"] = {
		strategy = "chat",
		description = "Create a README.md file for the project",
		opts = {
			index = 6,
			is_slash_cmd = true,
			ignore_system_prompt = false,
			auto_submit = false,
			alias = "readme",
		},
		prompts = {
			{
				role = "system",
				content = "use @{full_stack_dev} @{fetch_webpage}",
			},
			{
				role = "user",
				content = function()
					return get_prompt("create_readme.md")
				end,
				opts = {
					visible = true,
				},
			},
		},
	}
end

return Extension
