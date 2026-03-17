# Neovim Configuration

This project contains a modular, plugin-driven Neovim configuration, optimized for development in multiple languages and frameworks. It leverages the latest Neovim features and a curated set of plugins for productivity, code navigation, testing, and more.

## Features

- **Plugin Management:** Uses [lazy.nvim](https://github.com/folke/lazy.nvim) for fast, lazy-loaded plugin management.
- **Language Support:**
  - Treesitter for advanced syntax highlighting and code navigation (supports C, C++, Java, JSON, SCSS, CSS, Lua, Diff, Python, Rust, TSX, JavaScript, TypeScript, Bash, XML, C#, Vue, Angular, Go, and more).
  - LSP integration for diagnostics, code actions, and autocompletion.
- **Git Integration:**
  - [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) for inline git diff and hunk actions.
  - [vim-fugitive](https://github.com/tpope/vim-fugitive) for advanced git commands.
- **Testing:**
  - [neotest](https://github.com/nvim-neotest/neotest) with adapters for Go, Java, .NET, Jest, Vitest, and more.
- **Formatting:**
  - [conform.nvim](https://github.com/stevearc/conform.nvim) for code formatting (supports Prettier, Black, Stylua, CSharpier, etc.).
- **UI Enhancements:**
  - [which-key.nvim](https://github.com/folke/which-key.nvim) for keybinding discovery.
  - [harpoon](https://github.com/ThePrimeagen/harpoon) for quick file navigation.
  - [oil.nvim](https://github.com/stevearc/oil.nvim) as a modern file explorer.
  - [obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim) for markdown/Obsidian workflow.
  - [markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) for live markdown preview.
- **Database:**
  - [vim-dadbod-ui](https://github.com/kristijanhusak/vim-dadbod-ui) for database management.

## Setup

1. **Clone this repository** (or copy the `config/nvim` directory to your Neovim config path):
   ```sh
   git clone <repo-url> ~/.config/nvim
   ```
2. **Install [Neovim 0.12.0](https://neovim.io/)** or newer.
3. **Start Neovim**. Plugins will be installed automatically on first launch via `lazy.nvim`.
4. **(Optional) Install language servers and external tools** for full LSP and formatting support (see plugin docs for details).

## Usage

- `<Space>` is the leader key.
- Use `:Lazy` to manage plugins.
- Use `<leader>wv`/`<leader>wh` to split windows vertically/horizontally.
- Use `<leader>h` and `<leader>'` for Harpoon quick navigation.
- Use `<leader>mo` to open Markdown Preview.
- Use `:DBUIT` for database management.

## Directory Structure

- `init.lua` – Main entry point
- `lua/config/` – General settings and keymaps
- `lua/plugins/` – Plugin specifications and configs
- `md-preview/` – Custom CSS for markdown preview
- `snippets/` – Code snippets for supported languages
- `ftplugin/` – Filetype-specific settings

## Contributing

Feel free to open issues or PRs for improvements, new plugins, or bug fixes.

## License

MIT License
