local MiniTest = require('mini.test')

local T = MiniTest.new_set()

-- Helper: fresh child Neovim process for each case
local child = MiniTest.new_child_neovim()

T['builder'] = MiniTest.new_set({
	hooks = {
		pre_case = function()
			child.restart({ '-u', 'scripts/minimal_init.lua' })
		end,
	},
})

T['builder']['setup correctly after creation'] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')

		return builder.new() 
	]])
	MiniTest.expect.equality(#result.statusline, 0)
	MiniTest.expect.equality(#result.hl_stack, 0)
end

T['builder']['new builder returns empty string'] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')

		new_builder = builder.new() 

		return new_builder:build()
	]])
	MiniTest.expect.equality(result, "")
end

T['builder']['add - string is build when passed'] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')

		new_builder = builder.new():add('abc') 

		return new_builder:build()
	]])
	MiniTest.expect.equality(result, "abc")
end

T['builder']['add - function is correctly processed'] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')

		new_builder = builder.new():add(function()
			return 'abc'
		end) 

		return new_builder:build()
	]])
	MiniTest.expect.equality(result, "abc")
end

T['builder']['add_space - returns space character'] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')

		new_builder = builder.new():add_space() 

		return new_builder:build()
	]])
	MiniTest.expect.equality(result, " ")
end

T['builder']['add_space - character + length is processed correctly.'] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')

		new_builder = builder.new():add_space('|', 2) 

		return new_builder:build()
	]])
	MiniTest.expect.equality(result, "||")
end

T['builder']['add_hl_start - does not allow string'] = function()
	local ok, err = child.lua([[
		local builder = require('plugins.statusline.builder')

		new_builder = builder.new():add_hl_start('Special')

		return new_builder:build()
	]])
	MiniTest.expect.equality(ok, nil)
end

T['builder']['add_align - align characters are added'] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')

		new_builder = builder.new():add_align()

		return new_builder:build()
	]])
	MiniTest.expect.error(result)
end

-- T['eval_hl']['empty table returns empty string'] = function()
-- 	local result = child.lua([[
-- 		local highlight = require('plugins.statusline.highlight')
-- 		return highlight.eval_hl({})
-- 	]])
-- 	MiniTest.expect.equality(result, '')
-- end
--
-- T['eval_hl']['table with hl[true] returns empty string'] = function()
-- 	local result = child.lua([[
-- 		local highlight = require('plugins.statusline.highlight')
-- 		local hl = {}
-- 		hl[true] = true
-- 		return highlight.eval_hl(hl)
-- 	]])
-- 	MiniTest.expect.equality(result, '')
-- end
--
-- T['eval_hl']['simple RGB creates highlight and returns correct name'] = function()
-- 	local name = child.lua([[
-- 		vim.o.termguicolors = true
-- 		local highlight = require('plugins.statusline.highlight')
-- 		return highlight.eval_hl({ fg = '#FF0000', bg = '#000000' })
-- 	]])
-- 	MiniTest.expect.equality(name, 'StlFF0000_000000__')
--
-- 	-- Verify highlight was actually defined
-- 	local hl_exists = child.lua([[
-- 		local ok, _ = pcall(vim.api.nvim_get_hl, 0, { name = 'StlFF0000_000000__', create = false })
-- 		return ok
-- 	]])
-- 	MiniTest.expect.equality(hl_exists, true)
-- end
--
-- T['eval_hl']['named colors are resolved via load_colors'] = function()
-- 	local name = child.lua([[
-- 		vim.o.termguicolors = true
-- 		local highlight = require('plugins.statusline.highlight')
-- 		highlight.load_colors({ myred = '#FF0000' })
-- 		return highlight.eval_hl({ fg = 'myred' })
-- 	]])
-- 	MiniTest.expect.equality(name, 'StlFF0000___')
-- end
--
-- T['eval_hl']['styles are included in highlight name'] = function()
-- 	local name = child.lua([[
-- 		vim.o.termguicolors = true
-- 		local highlight = require('plugins.statusline.highlight')
-- 		return highlight.eval_hl({ fg = '#FF0000', bold = true })
-- 	]])
-- 	MiniTest.expect.equality(name, 'StlFF0000__bold_')
-- end
--
-- T['eval_hl']['cterm fallback name when termguicolors is disabled'] = function()
-- 	local name = child.lua([[
-- 		vim.o.termguicolors = false
-- 		local highlight = require('plugins.statusline.highlight')
-- 		return highlight.eval_hl({ ctermfg = 1, ctermbg = 2, bold = true })
-- 	]])
-- 	MiniTest.expect.equality(name, 'Stl1_2_bold')
-- end
--
-- T['eval_hl']['caching returns same name for identical input'] = function()
-- 	local results = child.lua([[
-- 		vim.o.termguicolors = true
-- 		local highlight = require('plugins.statusline.highlight')
-- 		local name1 = highlight.eval_hl({ fg = '#00FF00', bg = '#0000FF' })
-- 		local name2 = highlight.eval_hl({ fg = '#00FF00', bg = '#0000FF' })
-- 		return { name1, name2 }
-- 	]])
-- 	MiniTest.expect.equality(results[1], results[2])
-- 	MiniTest.expect.equality(results[1], 'Stl00FF00_0000FF__')
-- end
--
return T
