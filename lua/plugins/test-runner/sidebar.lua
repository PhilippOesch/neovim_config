local M = {}

--- The state of the sidebar
---
---@class test_runner.SidebarState
---@field buf integer|nil
---@field win integer|nil
---@field config { width: number, filetype: string, syntax: string }

---@class test_runner.Sidebar.new.opts
---@field width? number
---@field filetype? string
---@field syntax? string

---@class test_runner.Sidebar
---@field _state test_runner.SidebarState
---@field new fun(opts: test_runner.Sidebar.new.opts): test_runner.Sidebar
---@field open fun(self: test_runner.Sidebar)
---@field close fun(self: test_runner.Sidebar)
---@field toggle fun(self: test_runner.Sidebar)
---@field is_open fun(self: test_runner.Sidebar): boolean
---@field get_buf fun(self: test_runner.Sidebar): integer|nil
---@field set_content fun(self: test_runner.Sidebar, content: string)

---Create a new sidebar instance.
---@param opts test_runner.Sidebar.new.opts
---@return test_runner.Sidebar
function M.new(opts)
	opts = opts or {}
	local instance = {
		_state = {
			buf = nil,
			win = nil,
			config = {
				width = opts.width or 45,
				filetype = opts.filetype or "jestresults",
				syntax = opts.syntax or "markdown",
			},
		},
	}
	setmetatable(instance, { __index = M })
	return instance
end

---Ensure the sidebar buffer exists.
---@param self test_runner.Sidebar
---@return integer buf
local function ensure_buf(self)
	if self._state.buf and vim.api.nvim_buf_is_valid(self._state.buf) then
		return self._state.buf
	end
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false
	vim.bo[buf].filetype = self._state.config.filetype
	vim.bo[buf].syntax = self._state.config.syntax

	if vim.treesitter and vim.treesitter.language then
		pcall(vim.treesitter.language.register, "markdown", self._state.config.filetype)
	end

	self._state.buf = buf
	return buf
end

---Set the sidebar buffer content.
---@param content string
function M:set_content(content)
	local buf = ensure_buf(self)
	vim.bo[buf].modifiable = true
	local lines = vim.split(content, "\n")
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
end

---Open the sidebar window on the right.
function M:open()
	if self._state.win and vim.api.nvim_win_is_valid(self._state.win) then
		return
	end
	local current_win = vim.api.nvim_get_current_win()
	local buf = ensure_buf(self)
	vim.cmd("botright vsplit")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)
	vim.api.nvim_win_set_width(win, self._state.config.width)
	vim.wo[win].winfixwidth = true
	vim.wo[win].wrap = true
	vim.wo[win].foldmethod = "marker"
	vim.wo[win].foldlevel = 0
	vim.wo[win].conceallevel = 2
	vim.wo[win].concealcursor = "nvic"
	self._state.win = win

	-- Return focus to original window
	if vim.api.nvim_win_is_valid(current_win) then
		vim.api.nvim_set_current_win(current_win)
	end

	-- Close on q
	vim.keymap.set("n", "q", function()
		self:toggle()
	end, { buffer = buf, noremap = true, silent = true })
end

---Close the sidebar window.
function M:close()
	if self._state.win and vim.api.nvim_win_is_valid(self._state.win) then
		vim.api.nvim_win_close(self._state.win, true)
		self._state.win = nil
	end
end

---Toggle the sidebar visibility.
function M:toggle()
	if self._state.win and vim.api.nvim_win_is_valid(self._state.win) then
		self:close()
	else
		self:open()
	end
end

---Check if the sidebar window is currently open.
---@return boolean
function M:is_open()
	return self._state.win ~= nil and vim.api.nvim_win_is_valid(self._state.win)
end

---Get the sidebar buffer number.
---@return integer|nil
function M:get_buf()
	if self._state.buf and vim.api.nvim_buf_is_valid(self._state.buf) then
		return self._state.buf
	end
	return nil
end

return M
