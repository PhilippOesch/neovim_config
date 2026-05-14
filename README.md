# Neovim Configuration

This project contains a modular, plugin-driven Neovim configuration, optimized for development in multiple languages and frameworks. It leverages the latest Neovim features and a curated set of plugins for productivity, code navigation, testing, and more.

## Features

- **Plugin Management:** Uses Neovim’s built-in [vim.pack](https://neovim.io/) for fast, native plugin management, with a minimal wrapper for modular config and advanced features (see `lua/utils/plugin_manager.lua`).
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
3. **Start Neovim.** Plugins will be installed automatically on first launch using the native vim.pack system.
4. **(Optional) Install language servers and external tools** for full LSP and formatting support (see plugin docs for details).

## Testing

Unit tests for the custom statusline framework (and other Lua modules) are written with [`mini.test`](https://github.com/nvim-mini/mini.nvim) and run inside isolated headless Neovim child processes.

### Running tests

- **Run the full suite:**
  ```sh
  make test
  ```
- **Run a single test file:**
  ```sh
  make test_file FILE=tests/plugins/statusline/test_highlight.lua
  ```

The first run will automatically clone `mini.nvim` into `deps/`. Test files live under `tests/` and mirror the source structure in `lua/`.

## Plugin Management

- Plugins are defined as modular Lua tables in `lua/plugins/`.
- All plugin specs are loaded via a custom wrapper (`lua/utils/plugin_manager.lua`) that builds on top of vim.pack. This allows for custom build steps, dependency resolution, and `init` hooks.
- To add or customize a plugin, add/modify the relevant Lua file in `lua/plugins/` and refer to `plugin_manager.lua` for advanced options and extension points.
- The plugin manager uses `nvim-pack-lock.json` to keep plugin versions consistent. Normally, this is managed automatically, but you can delete it to force a full resync on your next launch if needed.

## Usage

- `<Space>` is the leader key.
- Use Neovim commands to work with plugins (see [`vim.pack`](https://neovim.io/)), .
- Use `<leader>wv`/`<leader>wh` to split windows vertically/horizontally.
- Use `<leader>h` and `<leader>'` for Harpoon quick navigation.
- Use `<leader>mo` to open Markdown Preview.
- Use `:DBUIT` for database management.

## Directory Structure

- `init.lua` – Main entry point
- `lua/config/` – General settings and keymaps
- `lua/plugins/` – Plugin specifications and configs
- `lua/utils/plugin_manager.lua` – Wrapper for plugin management (recommend reviewing for advanced usage)
- `md-preview/` – Custom CSS for markdown preview
- `snippets/` – Code snippets for supported languages
- `ftplugin/` – Filetype-specific settings

## Migration Notes

- **This config previously used lazy.nvim but now relies entirely on vim.pack.** Plugin specification and loading syntax have changed to be compatible with vim.pack and the custom wrapper. See the `lua/plugins/` examples for the current format.

## Contributing

Feel free to open issues or PRs for improvements, new plugins, or bug fixes. New plugins should be defined as modular Lua specs under `lua/plugins/`, and advanced integration can leverage features in `lua/utils/plugin_manager.lua`.

## License

MIT License
