return {
	deps = {
		"https://github.com/folke/sidekick.nvim",
	},
	init = function()
		local sidekick = require("sidekick")
		sidekick.setup({
			nes = {
				enabled = false,
			},
			cli = {
				mux = {
					backend = "tmux",
					enabled = true,
				},
				win = {
					config = function(terminal)
						local orig_open_win = terminal.open_win
						function terminal:open_win()
							orig_open_win(self)
							if self.win and vim.api.nvim_win_is_valid(self.win) then
								vim.api.nvim_win_call(self.win, function()
									vim.fn.winrestview({ leftcol = 0 })
								end)
							end
						end
					end,
				},
			},
			copilot = {
				-- track copilot's status with `didChangeStatus`
				status = {
					enabled = false,
					level = vim.log.levels.WARN,
					-- set to vim.log.levels.OFF to disable notifications
					-- level = vim.log.levels.OFF,
				},
			},
			tools = {
				opencode = {},
			},
		})

		vim.keymap.set("n", "<leader>it", function()
			require("sidekick.cli").toggle({ name = "opencode", focus = true })
		end, { desc = "Sidekick Toggle CLI" })
		vim.keymap.set("n", "<leader>ib", function()
			require("sidekick.cli").send({ msg = "{file}" })
		end, { desc = "Send File" })
		vim.keymap.set("x", "<leader>iv", function()
			require("sidekick.cli").send({ msg = "{selection}" })
		end, { desc = "Send Visual Selection" })
		-- {
		--   "<leader>aa",
		--   function() require("sidekick.cli").toggle() end,
		--   desc = "Sidekick Toggle CLI",
		-- },
	end,
}
