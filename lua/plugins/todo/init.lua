---@class Todo.Config
---@field todo_file? string
---@field width? number
---@field height? number

local get_default_config = function()
	return {
		todo_file = vim.fn.stdpath("data") .. "/todo.md",
		width = 0.6,
		height = 0.6,
	}
end

local default_file_content = [[# Todos
]]

local M = {}

local config = nil

---@class Todo.State
---@field buf? integer
---@field win? integer

---@type Todo.State
local state = {}

---@param state Todo.State
local function save_todo_file(state)
	if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
		return
	end

	local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
	local file = io.open(vim.fn.expand(config.todo_file), "w")
	if file then
		file:write(table.concat(lines, "\n") .. "\n")
		file:close()
		vim.api.nvim_buf_set_option(state.buf, "modified", false)
	else
		vim.notify("Failed to save todo file", vim.log.levels.ERROR)
	end
end

-- Ensure the todo file exists, create with initial content if needed
---comment
---@param file_path string
local function ensure_file_exists(file_path)
	file_path = vim.fn.expand(file_path)
	local parent_dir = vim.fn.fnamemodify(file_path, ":h")

	-- Create parent directory if it doesn't exist
	if vim.fn.isdirectory(parent_dir) == 0 then
		vim.fn.mkdir(parent_dir, "p")
	end

	-- Create file with initial header if it doesn't exist
	if vim.fn.filereadable(file_path) == 0 then
		local file = io.open(file_path, "w")
		if file then
			file:write(default_file_content)
			file:close()
		end
	end
end

---comment
---@param state Todo.State
local function create_floating_window(state)
	-- Get editor dimensions
	local ui = vim.api.nvim_list_uis()[1]
	local width = math.floor(ui.width * config.width)
	local height = math.floor(ui.height * config.height)

	-- Calculate center position
	local col = math.floor((ui.width - width) / 2)
	local row = math.floor((ui.height - height) / 2)

	-- Always create fresh buffer (since we delete on close)
	state.buf = vim.api.nvim_create_buf(false, false)

	-- Set buffer options
	vim.api.nvim_buf_set_option(state.buf, "filetype", "markdown")
	vim.api.nvim_buf_set_option(state.buf, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(state.buf, "buftype", "acwrite")

	-- Set buffer name with timestamp to ensure uniqueness
	local buf_name = string.format("todo://%s#%s", config.todo_file, vim.loop.hrtime())
	pcall(vim.api.nvim_buf_set_name, state.buf, buf_name)

	-- Setup write command for :w support
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = state.buf,
		callback = function()
			save_todo_file(state)
		end,
	})

	-- Auto-save on any buffer/window close event
	vim.api.nvim_create_autocmd({ "BufLeave", "WinClosed", "BufUnload" }, {
		buffer = state.buf,
		callback = function()
			if vim.api.nvim_buf_is_valid(state.buf) and vim.api.nvim_buf_get_option(state.buf, "modified") then
				save_todo_file(state)
			end
		end,
		desc = "Auto-save todo file on buffer/window close",
	})

	---@type vim.api.keyset.win_config
	local opts = {
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
	state.win = vim.api.nvim_open_win(state.buf, true, opts)

	-- Set window-local options
	vim.api.nvim_win_set_option(state.win, "winblend", 0)

	-- Load file content
	local file_path = vim.fn.expand(config.todo_file)
	local lines = {}
	local file = io.open(file_path, "r")
	if file then
		for line in file:lines() do
			table.insert(lines, line)
		end
		file:close()
	end
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(state.buf, "modified", false)

	-- Set buffer-local keymap for closing with 'q'
	vim.keymap.set("n", "q", function()
		M.close()
	end, { buffer = state.buf, noremap = true, silent = true, desc = "Close todo window" })
end

---setup plugin
---@param opts? Todo.Config
function M.setup(opts)
	config = vim.tbl_deep_extend("force", get_default_config(), opts or {})

	-- Auto-save before exiting Neovim
	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = function()
			if
				state.win
				and vim.api.nvim_buf_is_valid(state.buf)
				and vim.api.nvim_buf_get_option(state.buf, "modified")
			then
				save_todo_file(state)
			end
		end,
		desc = "Auto-save todo file before exiting Neovim",
	})

	-- todo setup global keumap seperatly
	vim.keymap.set("n", "<leader>do", function()
		M.toggle()
	end, { noremap = true, silent = true, desc = "Toggle todo" })

	-- Which-key integration
	require("which-key").add({
		{
			"<leader>do",
			icon = "",
		},
	})
end

-- Open todo window
function M.open()
	-- Don't open if already open
	if todo_win and vim.api.nvim_win_is_valid(todo_win) then
		return
	end

	ensure_file_exists(config.todo_file)
	create_floating_window(state)
end

-- Close todo window with buffer cleanup
function M.close()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
		state.win = nil
	end

	-- Unload buffer completely
	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		vim.api.nvim_buf_delete(state.buf, { force = true })
		state.buf = nil
	end
end

-- Toggle todo window
function M.toggle()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		M.close()
	else
		M.open()
	end
end

return M
