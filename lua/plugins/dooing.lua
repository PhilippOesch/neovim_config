---@type Config.Plugin
return {
	init = function()
		local M = {}

		-- Default configuration
		local config = {
			todo_file = vim.fn.stdpath("data") .. "/todo.md",
			width = 0.6,
			height = 0.6,
		}

		-- State tracking
		local todo_buf = nil
		local todo_win = nil

		-- Setup function to allow user configuration
		function M.setup(opts)
			config = vim.tbl_deep_extend("force", config, opts or {})
		end

		-- Ensure the todo file exists, create with initial content if needed
		local function ensure_file_exists()
			local file_path = vim.fn.expand(config.todo_file)
			local parent_dir = vim.fn.fnamemodify(file_path, ":h")

			-- Create parent directory if it doesn't exist
			if vim.fn.isdirectory(parent_dir) == 0 then
				vim.fn.mkdir(parent_dir, "p")
			end

			-- Create file with initial header if it doesn't exist
			if vim.fn.filereadable(file_path) == 0 then
				local file = io.open(file_path, "w")
				if file then
					file:write("# Todos\n")
					file:close()
				end
			end
		end

		-- Save buffer content to file
		local function save_todo_file()
			if not todo_buf or not vim.api.nvim_buf_is_valid(todo_buf) then
				return
			end

			local lines = vim.api.nvim_buf_get_lines(todo_buf, 0, -1, false)
			local file = io.open(vim.fn.expand(config.todo_file), "w")
			if file then
				file:write(table.concat(lines, "\n") .. "\n")
				file:close()
				vim.api.nvim_buf_set_option(todo_buf, "modified", false)
			else
				vim.notify("Failed to save todo file", vim.log.levels.ERROR)
			end
		end

		-- Create floating window
		local function create_floating_window()
			-- Get editor dimensions
			local ui = vim.api.nvim_list_uis()[1]
			local width = math.floor(ui.width * config.width)
			local height = math.floor(ui.height * config.height)

			-- Calculate center position
			local col = math.floor((ui.width - width) / 2)
			local row = math.floor((ui.height - height) / 2)

			-- Always create fresh buffer (since we delete on close)
			todo_buf = vim.api.nvim_create_buf(false, false)

			-- Set buffer options
			vim.api.nvim_buf_set_option(todo_buf, "filetype", "markdown")
			vim.api.nvim_buf_set_option(todo_buf, "bufhidden", "hide")
			vim.api.nvim_buf_set_option(todo_buf, "buftype", "acwrite")

			-- Set buffer name with timestamp to ensure uniqueness
			local buf_name = string.format("todo://%s#%s", config.todo_file, vim.loop.hrtime())
			pcall(vim.api.nvim_buf_set_name, todo_buf, buf_name)

			-- Setup write command for :w support
			vim.api.nvim_create_autocmd("BufWriteCmd", {
				buffer = todo_buf,
				callback = save_todo_file,
			})

			-- Auto-save on any buffer/window close event
			vim.api.nvim_create_autocmd({ "BufLeave", "WinClosed", "BufUnload" }, {
				buffer = todo_buf,
				callback = function()
					if vim.api.nvim_buf_is_valid(todo_buf) and vim.api.nvim_buf_get_option(todo_buf, "modified") then
						save_todo_file()
					end
				end,
				desc = "Auto-save todo file on buffer/window close",
			})

			-- Window options
			local opts = {
				relative = "editor",
				width = width,
				height = height,
				col = col,
				row = row,
				style = "minimal",
				border = "rounded",
			}

			-- Create window
			todo_win = vim.api.nvim_open_win(todo_buf, true, opts)

			-- Set window-local options
			vim.api.nvim_win_set_option(todo_win, "winblend", 0)

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
			vim.api.nvim_buf_set_lines(todo_buf, 0, -1, false, lines)
			vim.api.nvim_buf_set_option(todo_buf, "modified", false)

			-- Set buffer-local keymap for closing with 'q'
			vim.keymap.set("n", "q", function()
				M.close()
			end, { buffer = todo_buf, noremap = true, silent = true, desc = "Close todo window" })
		end

		-- Open todo window
		function M.open()
			-- Don't open if already open
			if todo_win and vim.api.nvim_win_is_valid(todo_win) then
				return
			end

			ensure_file_exists()
			create_floating_window()
		end

		-- Close todo window with buffer cleanup
		function M.close()
			if todo_win and vim.api.nvim_win_is_valid(todo_win) then
				vim.api.nvim_win_close(todo_win, true)
				todo_win = nil
			end

			-- Unload buffer completely
			if todo_buf and vim.api.nvim_buf_is_valid(todo_buf) then
				vim.api.nvim_buf_delete(todo_buf, { force = true })
				todo_buf = nil
			end
		end

		-- Toggle todo window
		function M.toggle()
			if todo_win and vim.api.nvim_win_is_valid(todo_win) then
				M.close()
			else
				M.open()
			end
		end

		-- Initialize with default config
		M.setup()

		-- Auto-save before exiting Neovim
		vim.api.nvim_create_autocmd("VimLeavePre", {
			callback = function()
				if
					todo_buf
					and vim.api.nvim_buf_is_valid(todo_buf)
					and vim.api.nvim_buf_get_option(todo_buf, "modified")
				then
					save_todo_file()
				end
			end,
			desc = "Auto-save todo file before exiting Neovim",
		})

		-- Set up global keymap
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
	end,
}
