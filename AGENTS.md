# Neovim Config — Agent Notes

Personal Neovim 0.12+ config. Plugin management is native `vim.pack` through a custom wrapper (`lua/utils/plugin_manager.lua`); specs use the wrapper's `Config.Plugin` format — lazy.nvim-style snippets from the web do not apply.

## Verify

- `make test` / `make test_file FILE=<path>` — `mini.test` suite, headless; details in README § Testing
- `make check` — headless parse of every Lua file; run before committing
- `nvim` not on PATH? It lives at `~/bin/nvim-macos-arm64/bin/nvim`

## Conventions

- One file per plugin in `lua/plugins/`, returning a `Config.Plugin` table; the field reference is the annotation block at the top of `lua/utils/plugin_manager.lua`
- Adding a plugin is two edits: the new `lua/plugins/<name>.lua`, plus a `require("plugins.<name>")` entry in the plugin list in `init.lua`
- Tests mirror the `lua/` layout under `tests/` and must be named `test_*.lua` (glob in `scripts/minimal_init.lua`); they run without any `vim.pack` plugins loaded, so stub `package.loaded[...]` for module dependencies (see `tests/plugins/test_rest_guard.lua`)

## Gotchas

- `nvim-pack-lock.json` is managed by `vim.pack`: commit the regenerated file, or delete it to force a full resync
- This repo is a git submodule of `~/dotfiles`; committing here does not move the parent's submodule pointer
- `.github/copilot-instructions.md` can lag the code (it references a statusline test file that no longer exists); trust the tree over the doc
- `init.lua` sets `exrc`, so `.nvim.lua` / `.exrc` files in other projects execute when you edit there
- Verify built-in API behavior (e.g. `vim.pack`) against the runtime source, not memory: `nvim --headless -u NONE -c 'lua print(vim.fn.globpath(&rtp, "lua/vim/pack.lua"))' -c q`
