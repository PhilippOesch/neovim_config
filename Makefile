LUA_FILES := $(shell find lua tests scripts ftplugin snippets -name '*.lua' 2>/dev/null) init.lua

.PHONY: test test_file check

deps/mini.nvim:
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/nvim-mini/mini.nvim $@

test: deps/mini.nvim
	nvim --headless --noplugin -u scripts/minimal_init.lua -c "lua MiniTest.run()"

test_file: deps/mini.nvim
	nvim --headless --noplugin -u scripts/minimal_init.lua -c "lua MiniTest.run_file('$(FILE)')"

check:
	@for f in $(LUA_FILES); do \
		nvim --headless -u NONE -c "lua assert(loadfile('$$f'))" -c 'q' || exit 1; \
	done
	@echo "All Lua files parsed successfully"
