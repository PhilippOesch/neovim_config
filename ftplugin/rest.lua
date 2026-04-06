vim.keymap.set("n", "<leader>Rs", require("kulala").run(), { desc = "Send request" })
vim.keymap.set("n", "<leader>Ra", require("kulala").run_all(), { desc = "Send all requests" })
vim.keymap.set("n", "<leader>Rb", require("kulala").scratchpad(), { desc = "Open scratchpad" })
