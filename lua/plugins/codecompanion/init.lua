---@alias Models table<string,string>

local function capitalize(s)
	if type(s) ~= "string" or s == "" then
		return s
	end
	return s:sub(1, 1):upper() .. s:sub(2)
end

---@class DefaultModels
---@field Copilot Models
---@field OpenCode Models
local model_mapping = {
	Copilot = {
		default = "gpt-5-mini",
		premium = "claude-sonnet-4.5",
		opus = "claude-opus-4.6",
	},
	OpenCode = {
		default = "github-copilot/gpt-5-mini",
		premium = "github-copilot/claude-sonnet-4.5",
		opus = "github-copilot/claude-opus-4.6",
	},
}

return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"ravitemer/codecompanion-history.nvim",
		{ "j-hui/fidget.nvim", opts = {} },
		{ import = "plugins.codecompanion.libs" },
	},
	lazy = true,
	opts = {
		log_level = "TRACE", -- TRACE|DEBUG|ERROR|INFO
		mcp = {
			servers = {
				["tavily"] = {
					cmd = { "npx", "-y", "tavily-mcp@latest" },
					env = {
						TAVILY_API_KEY = "TAVILY_API_KEY",
					},
				},
				["context7"] = {
					cmd = { "npx", "-y", "@upstash/context7-mcp" },
					env = {
						DEFAULT_MINIMUM_TOKENS = "10",
					},
				},
			},
			opts = {
				default_servers = { "context7" },
			},
		},
		rules = {
			default = {
				description = "Collection of common files for all projects",
				files = {
					".clinerules",
					".cursorrules",
					".goosehints",
					".rules",
					".windsurfrules",
					"$XDG_CONFIG_HOME/AGENTS.md",
					".github/copilot-instructions.md",
					"AGENT.md",
					"AGENTS.md",
					{ path = "CLAUDE.md", parser = "claude" },
					{ path = "CLAUDE.local.md", parser = "claude" },
					{ path = "~/.claude/CLAUDE.md", parser = "claude" },
				},
				-- is_preset = true,
			},
			opts = {
				chat = {
					enabled = true,
				},
			},
		},
		interactions = {
			background = {
				adapter = {
					name = "copilot",
					model = "gpt-4.1",
				},
				chat = {
					callbacks = {
						["on_ready"] = {
							actions = {
								"interactions.background.builtin.chat_make_title",
							},
							-- Enable "on_ready" callback which contains the title generation action
							enabled = true,
						},
					},
					opts = {
						-- Enable background interactions generally
						enabled = true,
					},
				},
			},
			chat = {
				tools = {
					opts = {
						auto_submit_errors = true, -- Send any errors to the LLM automatically?
						auto_submit_success = true, -- Send any successful output to the LLM automatically?
					},
					groups = {
						["full_stack_dev"] = {
							description = "Full Stack Developer - Can run code, edit code and modify files",
							prompt = "I'm giving you access to the ${tools} to help you perform coding tasks",
							tools = {
								"cmd_runner",
								"create_file",
								"delete_file",
								"file_search",
								"get_changed_files",
								"grep_search",
								"insert_edit_into_file",
								"list_code_usages",
								"read_file",
								"problems",
							},
							opts = {
								collapse_tools = true,
							},
						},
						["review"] = {
							description = "Expert Reviewer - Senior Software Engineer ",
							tools = {
								"file_search",
								"get_changed_files",
								"grep_search",
								"list_code_usages",
								"read_file",
								"problems",
							},
							opts = {
								collapse_tools = true,
							},
						},
						["research"] = {
							description = "Researcher - for planning tasks",
							tools = {
								"mcp:context7",
								"fetch_webpage",
								"tavily",
								"file_search",
								"grep_search",
								"list_code_usages",
								"read_file",
							},
							opts = {
								collapse_tools = true,
							},
						},
					},
				},
				-- adapter = "opencode",
				adapter = { name = "copilot", model = model_mapping["Copilot"].default },
				opts = {
					completion_provider = "blink",
				},
				roles = {
					---The header name for the LLM's messages
					---@type string|fun(adapter: CodeCompanion.Adapter): string
					llm = function(_)
						return "✨ CodeCompanion"
					end,

					---The header name for your messages
					---@type string
					user = "💬 Me",
				},
			},
		},
		adapters = {
			http = {
				opts = {
					show_presets = false,
					show_model_choices = true, -- Show model choices when changing adapter
				},
				copilot = function()
					return require("codecompanion.adapters").extend("copilot", {
						schema = {
							model = {
								default = model_mapping["Copilot"].default,
							},
						},
					})
				end,
			},
			acp = {
				opts = {
					show_presets = false,
				},
				opencode = function()
					return require("codecompanion.adapters").extend("opencode", {
						defaults = {
							model = model_mapping["OpenCode"].default,
						},
					})
				end,
			},
		},
		display = {
			chat = {
				-- Change the default icons
				icons = {
					buffer_pin = " ",
					buffer_watch = "👀 ",
				},
				show_tools_processing = true, -- Show the loading message when tools are being executed?

				-- Alter the sizing of the debug window
				debug_window = {
					---@return number|fun(): number
					width = vim.o.columns - 5,
					---@return number|fun(): number
					height = vim.o.lines - 2,
				},
				show_header_separator = false,

				-- Options to customize the UI of the chat buffer
				window = {
					layout = "vertical", -- float|vertical|horizontal|buffer
					position = nil, -- left|right|top|bottom (nil will default depending on vim.opt.splitright|vim.opt.splitbelow)
					border = "single",
					height = 0.8,
					width = 0.35,
					relative = "editor",
					full_height = true, -- when set to false, vsplit will be used to open the chat buffer vs. botright/topleft vsplit
					opts = {
						breakindent = true,
						cursorcolumn = false,
						cursorline = true,
						foldcolumn = "0",
						linebreak = true,
						list = false,
						numberwidth = 1,
						signcolumn = "no",
						spell = false,
						wrap = true,
					},
				},
			},
			diff = {
				enabled = true,
				close_chat_at = 80, -- Close an open chat buffer if the total columns of your display are less than...
				layout = "vertical", -- vertical|horizontal split for default provider
				opts = { "internal", "filler", "closeoff", "algorithm:patience", "followwrap", "linematch:120" },
			},
			action_palette = {
				width = 95,
				height = 10,
				prompt = "Prompt ", -- Prompt used for interactive LLM calls
				provider = "default", -- Can be "default", "telescope", "fzf_lua", "mini_pick" or "snacks". If not specified, the plugin will autodetect installed providers.
				opts = {
					show_preset_actions = false, -- Show the default actions in the action palette?
					show_preset_prompts = false, -- Show the default prompt library in the action palette?
					title = "CodeCompanion Actions", -- The title of the action palette
				},
			},
		},
		opts = {
			-- Set debug logging
			log_level = "DEBUG",
		},
		prompt_library = {
			markdown = {
				dirs = {
					"~/dotfiles/config/nvim/prompts", -- Or absolute paths
				},
			},
		},
		extensions = {
			history = {
				enabled = true,
				opts = {
					title_generation_opts = { adapter = "copilot", model = model_mapping["Copilot"].default },
				},
			},
			add_buffers = {
				enabled = true,
				opts = {
					excluded_filetypes = { "codecompanion", "oil" },
				},
			},
			background_color = {
				enabled = true,
			},
			fidget_spinner = {
				enabled = true,
			},
			list_chats = {
				enabled = true,
			},
			problems = {
				enabled = true,
			},
		},
	},
	config = function(_, opts)
		---@type CodeCompanion
		local codecompanion = require("codecompanion")

		codecompanion.setup(opts)

		vim.keymap.set("n", "<leader>it", ":CodeCompanionChat Toggle<CR>", {
			noremap = true,
			desc = "Toggle CodeCompanion chat",
		})
		vim.keymap.set({ "v" }, "<leader>ia", ":CodeCompanionChat Add<CR>", {
			noremap = true,
			desc = "Add selection to chat",
		})
		vim.keymap.set({ "n" }, "<leader>in", ":CodeCompanionChat<CR>", {
			noremap = true,
			desc = "New CodeCompanion Chat",
		})
		vim.keymap.set({ "n", "v" }, "<leader>ic", ":CodeCompanionActions<CR>", {
			noremap = true,
			desc = "Call codecompanion action",
		})
		vim.keymap.set({ "n" }, "<leader>igc", ":CodeCompanion /commit<CR>", {
			noremap = true,
			desc = "Generate Commit Message",
		})

		vim.keymap.set({ "n" }, "<leader>is", function()
			local chat = codecompanion.last_chat()

			if not chat then
				return
			end

			---@type Models
			local current_adapter = _G.codecompanion_chat_metadata[chat.bufnr].adapter.name

			local new_adapter = "Opencode"
			--
			if current_adapter == "OpenCode" then
				new_adapter = "Copilot"
			end
			--
			chat:change_adapter(string.lower(new_adapter))
			vim.notify(string.format('Adapter changed to: %s', new_adapter), vim.log.levels.INFO)
		end, {
			noremap = true,
			desc = "Switch between adapters",
		})

		vim.keymap.set({ "n" }, "<leader>im", function()
			local chat = codecompanion.last_chat()

			if not chat then
				return
			end

			---@type Models
			local adapter_models = model_mapping[_G.codecompanion_chat_metadata[chat.bufnr].adapter.name]
			--
			local items = vim.iter(pairs(adapter_models))
				:map(function(k, v)
					return { type = k, name = v }
				end)
				:totable()
			--
			vim.ui.select(items, {
				prompt = "Select Model from favorites",
				format_item = function(item)
					return string.format("%s - %s", item.type, item.name)
				end,
			}, function(item, _)
				if not item then
					return
				end
				chat:change_model({ model = item.name })
			end)
		end, {
			noremap = true,
			desc = "Toggle between free an premium model",
		})

		require("which-key").add({
			{
				"<leader>i",
				icon = "✨",
				group = "artificial (i)ntelligence - codecompanion",
			},
			{
				"<leader>it",
				icon = "✨󰭹",
			},
			{
				"<leader>ia",
				icon = "✨󰒅",
				mode = { "v" },
			},
			{
				"<leader>ic",
				icon = "✨",
				mode = { "n", "v" },
			},
			{
				"<leader>in",
				icon = "✨󱐏",
			},
			{
				"<leader>igc",
				icon = "✨",
			},
			{
				"<leader>im",
				icon = "✨✨",
			},
		})

		vim.api.nvim_create_user_command("CodeCompanionLogs", function()
			vim.cmd("tabnew ~/.local/state/nvim/codecompanion.log")
		end, {})
	end,
}
