local wk = require("which-key")
wk.setup()

wk.add({
	-- -- document existing key chains
	{ "<leader>c", group = "[C]ode", icon = "" },
	{ "<leader>d", group = "[D]ocument", icon = "󰈙" },
	{ "<leader>g", group = "[G]it", icon = "󰊢" },
	{ "<leader>h", group = "Git [H]unk", icon = "󰊢" },
	{ "<leader>r", group = "[R]ename", icon = "󰑕" },
	{ "<leader>s", group = "[S]earch", icon = "" },
	{ "<leader>t", group = "[T]oggle", icon = "󰨚" },
	{ "<leader>w", group = "[W]orkspace", icon = "" },
	-- -- register which-key VISUAL mode
	-- -- required for visual <leader>hs (hunk stage) to work
	{ mode = "v", { "<leader>", group = "VISUAL <leader>" }, { "<leader>h", desc = "Git [H]unk" } },
})
-- end,
-- }
