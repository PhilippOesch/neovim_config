local fmt = string.format
local log = require("codecompanion.utils.log")

---@param args {min_diagnostic_level?: string, bufnr?: integer}
---@return nil|{ status: "success"|"error", data: string }
local function get_lsp_infos(args)
	local min_diagnostic_level = "warn"
	if args.min_diagnostic_level ~= nil and type(args.min_diagnostic_level) == "string" then
		min_diagnostic_level = args.min_diagnostic_level
	end
	local bufnr = nil
	if args.bufnr ~= nil and type(args.bufnr) == "number" then
		bufnr = args.bufnr
	end

	local actionSeverity = vim.diagnostic.severity[min_diagnostic_level] or vim.diagnostic.severity.WARN

	local diagnostics = vim.diagnostic.get(bufnr, {
		severity = { min = actionSeverity },
	})

	local processed_diagonstics = {}

	for i, diagnostic in ipairs(diagnostics) do
		local diagString = i
			.. ". Issue "
			.. i
			.. "\n  - Location: Line "
			.. diagnostic.lnum
			.. "\n  - Buffer: "
			.. diagnostic.bufnr
			.. "\n  - Severity: "
			.. diagnostic.severity
			.. "\n  - Message: "
			.. diagnostic.message
			.. "\n"
		table.insert(processed_diagonstics, diagString)
	end

	return { status = "success", data = processed_diagonstics }
end

---@type CodeCompanion.Tools.Tool
local Problems = {
	name = "problems",
	cmds = {

		---Execute the search commands
		---@param self CodeCompanion.Tools.Tool
		---@param args table The arguments from the LLM's tool call
		---@param input? any The output from the previous function call
		---@return { status: "success"|"error", data: string }
		function(self, args, input)
			return get_lsp_infos(args)
		end,
	},
	schema = {
		type = "function",
		["function"] = {
			name = "problems",
			description = "Get potential issues detected by the language server",
			strict = true,
			parameters = {
				type = "object",
				properties = {
					min_diagnostic_level = {
						type = { "string", "null" },
						enum = { "hint", "warn", "error", "info" },
						description = "the minimum level of the diagnostic results to filter for. The allowed values are: 'error', 'warn', 'info', and 'hint'. If not provided, the minimum level 'warn' should be used for 'min_diagnostic_level'.",
					},
					bufnr = {
						type = { "integer", "null" },
						description = "**THIS PROPERTY IS OPTIONAL!!!**. The buffer number of the file to analyse. If the user provides you a file name. Search whether you have the file inside your context and use it's 'bufnr",
					},
				},
				required = { "min_diagnostic_level", "bufnr" },
				additionalProperties = false,
			},
		},
	},
	handlers = {
		---@param tools CodeCompanion.Tools The tool object
		---@return nil
		on_exit = function(tools)
			log:trace("[Problems Tool] on_exit handler executed")
		end,
	},
	output = {
		---@param self CodeCompanion.Tool.GetChangedFiles
		---@param tools CodeCompanion.Tools
		prompt = function(self, tools)
			return "Get language server diagnostics?"
		end,

		---@param self CodeCompanion.Tool.GetChangedFiles
		---@param tools CodeCompanion.Tools
		---@param cmd table The command that was executed
		---@param stdout table The output from the command
		success = function(self, tools, cmd, stdout)
			-- local args = self.args
			local chat = tools.chat

			local content = vim.iter(stdout):flatten():join("\n")

			local llm_output = fmt([[<Diagnostics>%s</Diagnostics>]], content)
			local user_output = "Fetched Diagnostics"

			chat:add_tool_output(self, llm_output, user_output)
		end,

		---@param self CodeCompanion.Tool.GetChangedFiles
		---@param tools CodeCompanion.Tools
		---@param cmd table
		---@param stderr table The error output from the command
		error = function(self, tools, cmd, stderr)
			-- local args = self.args
			local chat = tools.chat
			local errors = vim.iter(stderr):flatten():join("\n")
			log:debug("[Problems Tool] Error output: %s", stderr)

			local error_output = fmt(
				[[Error fetching Diagnostics`:
```txt
%s
```]],
				errors
			)
			chat:add_tool_output(self, error_output)
		end,

		---Rejection message back to the LLM
		---@param self CodeCompanion.Tool.GetChangedFiles
		---@param tools CodeCompanion.Tools
		---@param cmd table
		---@return nil
		rejected = function(self, tools, cmd)
			local chat = tools.chat
			chat:add_tool_output(self, "The user declined to get language server diagnostics")
		end,
	},
}

return Problems
