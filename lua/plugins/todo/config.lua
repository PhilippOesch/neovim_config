local M = {}

---@class Todo.Config.Win.Keymaps
---@field close? string

---@class Todo.Config.Win
---@field keymaps? Todo.Config.Win.Keymaps

---@class Todo.Config
---@field todo_file? string
---@field width? number
---@field height? number
---@field win? Todo.Config.Win
---@field default_file_content? string

---@type Todo.Config
M.config = nil

---get the default configuration
---@return Todo.Config
function M.get_default_config()
	---@type Todo.Config
	return {
		todo_file = vim.fn.stdpath("data") .. "/todo.md",
		width = 0.6,
		height = 0.6,
		win = {
			keymaps = {
				close = "q",
			},
		},
		default_file_content = [[# Todos
]],
	}
end

---comment
---@param config? Todo.Config
function M.init(config)
	M.config = vim.tbl_deep_extend("force", M.get_default_config(), config or {})
end

return M
