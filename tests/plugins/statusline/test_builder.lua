local MiniTest = require("mini.test")

local T = MiniTest.new_set()

-- Helper: fresh child Neovim process for each case
local child = MiniTest.new_child_neovim()

local function mock_highlight()
	child.lua([[                                                           
             package.loaded['plugins.statusline.highlight'] = {                 
                 eval_hl = function(hl) return 'MockHl' end,                    
                 load_colors = function() end,                                  
                 get_highlight = function(name) return {} end,                  
             }                                                                  
         ]])
end

T["builder"] = MiniTest.new_set({
	hooks = {
		pre_case = function()
			child.restart({ "-u", "scripts/minimal_init.lua" })
			mock_highlight()
		end,
	},
})

T["builder"]["setup correctly after creation"] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')

		return builder.new() 
	]])
	MiniTest.expect.equality(#result.statusline, 0)
	MiniTest.expect.equality(#result.hl_stack, 0)
end

T["builder"]["new builder returns empty string"] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')

		new_builder = builder.new() 

		return new_builder:build()
	]])
	MiniTest.expect.equality(result, "")
end

T["builder"]["add - string is build when passed"] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')

		new_builder = builder.new():add('abc') 

		return new_builder:build()
	]])
	MiniTest.expect.equality(result, "abc")
end

T["builder"]["add - function is correctly processed"] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')

		new_builder = builder.new():add(function()
			return 'abc'
		end) 

		return new_builder:build()
	]])
	MiniTest.expect.equality(result, "abc")
end

T["builder"]["add_space - returns space character"] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')

		new_builder = builder.new():add_space() 

		return new_builder:build()
	]])
	MiniTest.expect.equality(result, " ")
end

T["builder"]["add_space - character + length is processed correctly."] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')

		new_builder = builder.new():add_space('|', 2) 

		return new_builder:build()
	]])
	MiniTest.expect.equality(result, "||")
end

T["builder"]["add_align - align characters are added"] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')

		new_builder = builder.new():add_align()

		return new_builder:build()
	]])
	MiniTest.expect.error(result)
end

T["builder"]["add_hl_start - does not create highlight if no string set at allo"] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')
		local b = builder.new():add_hl_start(
			{fg= "#00FF00"}
		)
		return b:build()
	]])
	MiniTest.expect.equality(result, "")
end

T["builder"]["add_hl_start - should add highlight to stack"] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')
		local b = builder.new():add_hl_start(
			{fg= "#00FF00"}
		)
		return #b.hl_stack
	]])
	MiniTest.expect.equality(result, 1)
end

T["builder"]["add_hl_end - should remove highlight from stack"] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')
		local b = builder.new():add_hl_start(
			{fg= "#00FF00"}
		):add_hl_end()
		return #b.hl_stack
	]])
	MiniTest.expect.equality(result, 0)
end

T["builder"]["add - highlight table should be processed as expected"] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')
		local b = builder.new():add(function()
			return "abc"
		end, {fg= "#00FF00"})
		return b:build()
	]])
	MiniTest.expect.equality(result, "%#MockHl#abc%*")
end

T["builder"]["add - highlight function should be processed as expected"] = function()
	local result = child.lua([[
		local builder = require('plugins.statusline.builder')
		local b = builder.new():add(function()
			return "abc"
		end, function ()
			return {fg= "#00FF00"}
		end)
		return b:build()
	]])
	MiniTest.expect.equality(result, "%#MockHl#abc%*")
end

T["builder"]["stacking higlight groups works as expected"] = function()
	local result = child.lua([[
		package.loaded['plugins.statusline.highlight'] = {                 
		    eval_hl = function(hl) 
				return hl.fg
		    end,                    
		    load_colors = function() end,                                  
		    get_highlight = function(name) return {} end,                  
		}                                                                  

		local builder = require('plugins.statusline.builder')
		local b = builder.new()
			:add_hl_start({fg= "MockHl1"})
			:add(function()
				return "abc"
			end, {fg= "MockHl2"})
			:add(function()
				return "def"
			end)
			:add_hl_end()
		return b:build()
	]])
	MiniTest.expect.equality(result, "%#MockHl2#abc%*%#MockHl1#def%*")
end

T["builder"]["add_hl_end - does not end group if nothing to group"] = function()
	local ok = child.lua([[
		local builder = require('plugins.statusline.builder')
		local b = builder.new():add_hl_end()
		return b:build()
	]])
	MiniTest.expect.equality(ok, "")
end

return T
