vim.g.mkdp_filetypes = { "markdown" }
vim.g.mkdp_markdown_css = vim.fn.stdpath("config") .. "/md-preview/style.css"
vim.g.mkdp_highlight_css = vim.fn.stdpath("config") .. "/md-preview/highlight.css"

vim.keymap.set("n", "<leader>mo", "<cmd> MarkdownPreview<CR>", {
	noremap = true,
	desc = "Open Markdown Preview",
})
vim.keymap.set("n", "<leader>ms", "<cmd> MarkdownPreviewStop<CR>", {
	noremap = true,
	desc = "Open Markdown Preview",
})
vim.keymap.set("n", "<leader>mt", "<cmd> MarkdownPreview<CR>", {
	noremap = true,
	desc = "Toggle Markdown",
})
