local highlight = require("plugins.statusline.highlight")
local vimode = require("plugins.statusline.vimode")
local ruler = require("plugins.statusline.ruler")

local Builder = {}
Builder.__index = Builder

---@class Builder
---@field statusline (eval_fun|string)[]
---@field hl_stack hl_val[]
---@field new fun(hl?: hl_val): Builder
---@field add fun(self: Builder, fn: eval_fun, hl?: hl_val): Builder
---@field add_filename fun(self: Builder, hl?: hl_val): Builder
---@field add_file_icon fun(self: Builder): Builder
---@field add_block fun(self: Builder, hl?: hl_val): Builder
---@field add_align fun(self: Builder): Builder
---@field add_space fun(self: Builder, chars?: string, len?: integer): Builder
---@field add_scrollbar fun(self: Builder, hl?: hl_val): Builder
---@field add_ruler fun(self: Builder, hl?: hl_val): Builder
---@field add_surround fun(self: Builder, left: string, right: string, fn: eval_fun_builder, hl?: hl_val): Builder
---@field add_conditional fun(self: Builder, fn: eval_fun_builder, predicate: condition_fun): Builder
---@field add_mode fun(self: Builder, hl?: hl_val): Builder
---@field add_hl_start fun(self: Builder, hl: hl_val): Builder
---@field add_hl_end fun(self: Builder): Builder
---@field build fun(self: Builder): string

---@alias eval_fun fun():string
---@alias eval_fun_builder fun(bld: Builder)
---@alias condition_fun fun():boolean
---@alias hl_val table|function

---@param hl? hl_val
---@return Builder
function Builder.new(hl)
	local self = setmetatable({}, Builder)

	---@type eval_fun[]
	self.statusline = {}
	self.hl_stack = {}
	if hl then
		self.hl_stack = { hl }
	end

	return self
end

local function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == "table" then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else
		copy = orig
	end
	return copy
end

local function resolve_dynamic_hl(hl)
	while type(hl) == "function" do
		hl = hl()
	end
	return hl
end

---@param hl? hl_val
---@return Builder
function Builder:add_hl_start(hl)
	local hl_fn = function()
		return highlight.eval_hl(hl)
	end

	if type(hl) == "table" and #self.hl_stack > 0 then
		local parent_hl = self.hl_stack[#self.hl_stack]
		hl_fn = function()
			local from_stack = resolve_dynamic_hl(parent_hl)
			if type(from_stack) == "string" then
				from_stack = highlight.get_highlight(from_stack)
			end
			return highlight.eval_hl(vim.tbl_extend("force", from_stack, hl))
		end
	end

	if type(hl) == "function" then
		local current_stack = deepcopy(self.hl_stack)
		hl_fn = function()
			local evaluated_hl = resolve_dynamic_hl(hl)
			if type(evaluated_hl) == "table" and #current_stack > 0 then
				local from_stack = resolve_dynamic_hl(current_stack[#current_stack])
				if type(from_stack) == "string" then
					from_stack = highlight.get_highlight(from_stack)
				end
				evaluated_hl = vim.tbl_extend("force", from_stack, evaluated_hl)
			end
			return highlight.eval_hl(evaluated_hl)
		end
	end
	table.insert(self.hl_stack, hl_fn)
	-- table.insert(self.statusline, function()
	-- 	return "%#" .. hl_fn() .. "#"
	-- end)
	return self
end

---@return Builder
function Builder:add_hl_end()
	if #self.hl_stack > 0 then
		table.remove(self.hl_stack, #self.hl_stack)
	end
	return self
end

---add new eval function
---@param fn eval_fun|string
---@param hl? hl_val
---@return Builder
function Builder:add(fn, hl)
	hl = hl or (#self.hl_stack > 0 and self.hl_stack[#self.hl_stack])
	local hl_fn = function()
		local resolve_hl = resolve_dynamic_hl(hl)
		if type(resolve_hl) == "table" then
			return highlight.eval_hl(resolve_hl)
		end
		return hl()
	end
	if hl then
		table.insert(self.statusline, "%#" .. hl_fn() .. "#")
		table.insert(self.statusline, fn)
		table.insert(self.statusline, "%*")
	else
		table.insert(self.statusline, fn)
	end
	return self
end

---add new eval function
---@param fn eval_fun_builder
---@param hl? hl_val
---@return Builder
function Builder:add_block(fn, hl)
	if #self.statusline > 0 then
		self:add_align()
	end
	if hl then
		self:add_hl_start(hl)
		fn(self)
		self:add_hl_end()
	else
		fn(self)
	end
	return self
end

---@param fn eval_fun_builder
---@param predicate condition_fun
---@return Builder
function Builder:add_conditional(fn, predicate)
	local conditional_builder = Builder.new((#self.hl_stack > 0 and self.hl_stack[#self.hl_stack]) or nil)
	fn(conditional_builder)
	self:add(function()
		if predicate() then
			return conditional_builder:build()
		end
		return ""
	end)
	return self
end

local web_icons_available, web_icons = pcall(require, "nvim-web-devicons")

---@return Builder
function Builder:add_file_icon()
	self:add_conditional(function(bld)
		bld:add(function()
			local filename = vim.api.nvim_buf_get_name(0)
			local extension = vim.fn.fnamemodify(filename, ":e")
			local icon, _ = web_icons.get_icon_color(filename, extension, { default = true })
			return icon
		end, function()
			local filename = vim.api.nvim_buf_get_name(0)
			local extension = vim.fn.fnamemodify(filename, ":e")
			local _, icon_color = web_icons.get_icon_color(filename, extension, { default = true })
			return { fg = icon_color }
		end)
	end, function()
		return web_icons_available
	end)
	return self
end

---@param hl hl_val
---@return Builder
function Builder:add_filename(hl)
	self:add(function()
		return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
	end, hl)
	return self
end

---@param hl hl_val
---@return Builder
function Builder:add_scrollbar(hl)
	ruler.add_scrollbar(self, hl)
	return self
end

---@param hl hl_val
---@return Builder
function Builder:add_ruler(hl)
	ruler.add_ruler(self, hl)
	return self
end

---@return Builder
function Builder:add_align()
	self:add("%=")
	return self
end

---comment
---@param chars? string
---@param len? integer
---@return Builder
function Builder:add_space(chars, len)
	self:add(string.rep(chars or " ", len or 1))
	return self
end

---@param left string
---@param right string
---@param fn eval_fun_builder
---@param hl? string
---@return Builder
function Builder:add_surround(left, right, fn, hl)
	if hl then
		self:add(function()
			return left
		end, hl)
		self:add_hl_start(((type(hl) == "table" and hl.fg) and { bg = hl.fg }))
		fn(self)
		self:add_hl_end()
		self:add(function()
			return right
		end, hl)
	else
		self:add(function()
			return left
		end)
		fn(self)
		self:add(function()
			return right
		end)
	end
	return self
end

---@return Builder
function Builder:add_mode()
	vimode.add_mode(self)
	return self
end

---@return string
function Builder:build()
	local res = ""
	for _, value in ipairs(self.statusline) do
		if type(value) == "string" then
			res = res .. value
		elseif type(value) == "function" then
			res = res .. value()
		end
	end
	return res
end

return Builder
