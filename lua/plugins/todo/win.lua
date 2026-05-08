local config = require("plugins.todo.config")

---@class Todo.Win
---@field state Todo.State
---@field init fun(self: Todo.Win)
---@field open fun(self: Todo.Win)
---@field close fun(self: Todo.Win)
---@field toggle fun(self: Todo.Win)


local function get_todo_path()
	return _G.todo_path or config.config.todo_file
end

---comment
---@param state Todo.State
local function restore_cursor_position(state)
	if state.cursor_pos then
		pcall(vim.api.nvim_win_set_cursor, state.win, state.cursor_pos)
	else
		-- default to start of file
		pcall(vim.api.nvim_win_set_cursor, state.win, { 1, 0 })
	end
end

---comment
---@param state Todo.State
local function set_todo_filetype(state)
	vim.bo[state.buf].syntax = "markdown"
	vim.bo[state.buf].filetype = "todo" -- keep filetype for ftplugin logic

	if vim.treesitter and vim.treesitter.language then
		pcall(vim.treesitter.language.register, "markdown", "todo")
	end

	-- Common markdown-like buffer options (optional but recommended)
	vim.wo[state.win].spell = true
	vim.wo[state.win].foldmethod = "expr"
	vim.wo[state.win].foldexpr = "nvim_treesitter#foldexpr()"
	-- Keep commentstring compatible with markdown
	vim.bo[state.buf].commentstring = "<!-- %s -->"
end

---@param state Todo.State
local function save_todo_file(state)
	if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
		return
	end

	local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
	local file = io.open(vim.fn.expand(get_todo_path()), "w")
	if file then
		file:write(table.concat(lines, "\n") .. "\n")
		file:close()
		vim.api.nvim_set_option_value("modified", false, { buf = state.buf })
	else
		vim.notify("Failed to save todo file", vim.log.levels.ERROR)
	end
end

---comment
---@param state Todo.State
local function save_cursor_position(state)
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		local ok, cur = pcall(vim.api.nvim_win_get_cursor, state.win)
		if ok then
			state.cursor_pos = cur
		end
	end
end

-- Ensure the todo file exists, create with initial content if needed
---comment
---@param file_path string
local function ensure_file_exists(file_path)
	vim.notify("Ensure path exists: " .. file_path, vim.log.levels.INFO)
	file_path = vim.fn.expand(file_path)
	local parent_dir = vim.fn.fnamemodify(file_path, ":h")
	vim.notify(parent_dir, vim.log.levels.INFO)

	-- Create parent directory if it doesn't exist
	if vim.fn.isdirectory(parent_dir) == 0 then
		vim.fn.mkdir(parent_dir, "p")
		vim.notify("create path" .. parent_dir)
	end

	-- Create file with initial header if it doesn't exist
	if vim.fn.filereadable(file_path) == 0 then
		local file = io.open(file_path, "w")
		if file then
			file:write(config.config.default_file_content)
			file:close()
		end
	end
end

local Win = {}
Win.__index = Win

---Create new window.
---@return Todo.Win
function Win.new()
	local self = setmetatable({}, Win)
	self.state = {}
	return self
end

---open window.
function Win:open()
	if self.state.win and vim.api.nvim_win_is_valid(self.state.win) then
		return
	end

	ensure_file_exists(get_todo_path())
	self:create_floating_window()
end

---close window.
function Win:close()
	if self.state.win and vim.api.nvim_win_is_valid(self.state.win) then
		save_cursor_position(self.state)
		vim.api.nvim_win_close(self.state.win, true)
		self.state.win = nil
	end

	-- Unload buffer completely
	if self.state.buf and vim.api.nvim_buf_is_valid(self.state.buf) then
		vim.api.nvim_buf_delete(self.state.buf, { force = true })
		self.state.buf = nil
	end
end

---initialize window
function Win:init()
	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = function()
			if
				self.state.win
				and vim.api.nvim_buf_is_valid(self.state.buf)
				and vim.api.nvim_get_option_value("modified", { buf = self.state.buf })
			then
				save_todo_file(self.state)
			end
		end,
		desc = "Auto-save todo file before exiting Neovim",
	})
end

---Toggle window
function Win:toggle()
	if self.state.win and vim.api.nvim_win_is_valid(self.state.win) then
		self:close()
	else
		self:open()
	end
end

---Create floating window
function Win:create_floating_window()
	-- Get editor dimensions
	local ui = vim.api.nvim_list_uis()[1]
	local width = math.floor(ui.width * config.config.width)
	local height = math.floor(ui.height * config.config.height)

	-- Calculate center position
	local col = math.floor((ui.width - width) / 2)
	local row = math.floor((ui.height - height) / 2)

	-- Always create fresh buffer (since we delete on close)
	self.state.buf = vim.api.nvim_create_buf(false, false)

	-- Set buffer options
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = self.state.buf })
	vim.api.nvim_set_option_value("bufhidden", "hide", { buf = self.state.buf })
	vim.api.nvim_set_option_value("buftype", "acwrite", { buf = self.state.buf })

	-- Set buffer name with timestamp to ensure uniqueness
	local buf_name = string.format("todo://%s#%s", get_todo_path(), vim.loop.hrtime())
	pcall(vim.api.nvim_buf_set_name, self.state.buf, buf_name)

	-- Setup write command for :w support
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = self.state.buf,
		callback = function()
			save_todo_file(self.state)
			save_cursor_position(self.state)
		end,
	})

	-- Auto-save on any buffer/window close event
	vim.api.nvim_create_autocmd({ "BufLeave", "WinClosed", "BufUnload" }, {
		buffer = self.state.buf,
		callback = function()
			save_cursor_position(self.state)

			if
				vim.api.nvim_buf_is_valid(self.state.buf)
				and vim.api.nvim_get_option_value("modified", { buf = self.state.buf })
			then
				save_todo_file(self.state)
			end
		end,
		desc = "Auto-save todo file on buffer/window close",
	})

	---@type vim.api.keyset.win_config
	local win_opts = {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
		title = "Todos:",
	}

	-- Create window
	self.state.win = vim.api.nvim_open_win(self.state.buf, true, win_opts)

	set_todo_filetype(self.state)

	-- Set window-local options
	vim.api.nvim_set_option_value("winblend", 0, { win = self.state.win })

	-- Load file content
	local file_path = vim.fn.expand(get_todo_path())
	local lines = {}
	local file = io.open(file_path, "r")
	if file then
		for line in file:lines() do
			table.insert(lines, line)
		end
		file:close()
	end
	vim.api.nvim_buf_set_lines(self.state.buf, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modified", false, { buf = self.state.buf })

	restore_cursor_position(self.state)

	-- Set buffer-local keymap for closing with 'q'
	vim.keymap.set("n", config.config.win.keymaps.close, function()
		self:close()
	end, { buffer = self.state.buf, noremap = true, silent = true, desc = "Close todo window" })
end


return Win
