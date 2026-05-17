local M = {}

---@class test_runner.SidebarState
---@field buf integer|nil
---@field win integer|nil
---@field config { width: number, filetype: string, syntax: string }

---@class test_runner.Sidebar
---@field _state test_runner.SidebarState

---Create a new sidebar instance.
---@param opts { width?: number, filetype?: string, syntax?: string }
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
---@param self test_runner.Sidebar
---@param content string
function M.set_content(self, content)
	local buf = ensure_buf(self)
	vim.bo[buf].modifiable = true
	local lines = vim.split(content, "\n")
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
end

---Open the sidebar window on the right.
---@param self test_runner.Sidebar
function M.open(self)
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
---@param self test_runner.Sidebar
function M.close(self)
	if self._state.win and vim.api.nvim_win_is_valid(self._state.win) then
		vim.api.nvim_win_close(self._state.win, true)
		self._state.win = nil
	end
end

---Toggle the sidebar visibility.
---@param self test_runner.Sidebar
function M.toggle(self)
	if self._state.win and vim.api.nvim_win_is_valid(self._state.win) then
		self:close()
	else
		self:open()
	end
end

---Check if the sidebar window is currently open.
---@param self test_runner.Sidebar
---@return boolean
function M.is_open(self)
	return self._state.win ~= nil and vim.api.nvim_win_is_valid(self._state.win)
end

---Get the sidebar buffer number.
---@param self test_runner.Sidebar
---@return integer|nil
function M.get_buf(self)
	if self._state.buf and vim.api.nvim_buf_is_valid(self._state.buf) then
		return self._state.buf
	end
	return nil
end

return M
