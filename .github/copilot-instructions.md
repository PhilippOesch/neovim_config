# Copilot Coding Agent Instructions for Dotfiles Repository

## Repository Overview

This repo represents a neovim config.

**Repository Info:**
- Tested with Neovim v0.12 
- **Type**: Lua-based configuration using Neovim’s native vim.pack for plugin management, extended by a custom wrapper (`lua/utils/plugin_manager.lua`).

## Repository Structure

```
  - `init.lua` - Entry point
  - `nvim-pack-lock.json` - Plugin version lock file (for vim.pack)
  - `lua/` - Configuration modules
  - `lua/utils/plugin_manager.lua` - Custom plugin loader/wrapper for modular plugins
  - `snippets/` - Code snippets
```

## Setup and Installation

### Initial Setup

**Clone the repository to the expected neovim config location:**
```bash
  git clone <repo> ~/.config/nvim
```
- Install [Neovim 0.12.0](https://neovim.io/) or newer.
- Start Neovim. Plugins will be installed automatically on first launch using vim.pack.

