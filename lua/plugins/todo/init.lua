local config = require("plugins.todo.config")
local win = require("plugins.todo.win")

local M = {}

---@class Todo.State
---@field buf? integer
---@field win? integer
---@field cursor_pos? [integer, integer]

---@type Todo.Win
local current_win

---setup plugin
---@param opts? Todo.Config
function M.setup(opts)
	config.init(opts)

	current_win = win.new()
	current_win:init()
end

-- Open todo window
function M.open()
	current_win:open()
end

-- Close todo window with buffer cleanup
function M.close()
	current_win:close()
end

-- Toggle todo window
function M.toggle()
	current_win:toggle()
end

return M
