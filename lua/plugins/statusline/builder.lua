local highlight = require("plugins.statusline.highlight")

local Builder = {}
Builder.__index = Builder

---@class Builder
---@field statusline eval_fun[]
---@field hl_stack (string|table|function)[]
---@field new fun(hl?: string|table): Builder
---@field add fun(self: Builder, fn: eval_fun, hl?: string|function|table): Builder
---@field add_filename fun(self: Builder): Builder
---@field add_align fun(self: Builder): Builder
---@field add_space fun(self: Builder, chars?: string, len?: integer): Builder
---@field add_surround fun(self: Builder, left: string, right: string, fn: eval_fun_builder, hl?: string|table): Builder
---@field add_conditional fun(self: Builder, fn: eval_fun_builder, predicate: condition_fun): Builder
---@field add_mode fun(self: Builder, hl?: string|function|table): Builder
---@field add_hl_start fun(self: Builder, hl: string|table|function): Builder
---@field add_hl_end fun(self: Builder): Builder
---@field build fun(self: Builder): string

---@alias eval_fun fun():string
---@alias eval_fun_builder fun(self: Builder)
---@alias condition_fun fun():boolean

---@param hl? string|table
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

function Builder:add_hl_start(hl)
	local hl_fn = function()
		return highlight.eval_hl(hl)
	end
	if type(hl) == "table" and #self.hl_stack > 0 then
		hl = vim.tbl_extend("force", self.hl_stack[#self.hl_stack], hl)
	end

	if type(hl) == "function" then
		local current_stack = deepcopy(self.hl_stack)
		hl_fn = function()
			local evaluated_hl = hl()
			if type(evaluated_hl) == "table" and #current_stack > 0 then
				evaluated_hl = vim.tbl_extend("force", current_stack[#current_stack], evaluated_hl)
			end
			return highlight.eval_hl(evaluated_hl)
		end
	end
	table.insert(self.hl_stack, hl)
	table.insert(self.statusline, function()
		return "%#" .. hl_fn() .. "#"
	end)
end
function Builder:add_hl_end()
	if #self.hl_stack > 0 then
		table.remove(self.hl_stack, #self.hl_stack)
	end
	table.insert(self.statusline, function()
		return "%*"
	end)
end

---add new eval function
---@param fn eval_fun
---@param hl? string
---@return Builder
function Builder:add(fn, hl)
	if hl then
		self:add_hl_start(hl)
		table.insert(self.statusline, fn)
		self:add_hl_end()
	else
		table.insert(self.statusline, fn)
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

---@return Builder
function Builder:add_filename()
	self:add(function()
		return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
	end)
	return self
end

---@return Builder
function Builder:add_align()
	self:add(function()
		return "%="
	end)
	return self
end

---comment
---@param chars? string
---@param len? integer
---@return Builder
function Builder:add_space(chars, len)
	self:add(function()
		return string.rep(chars or " ", len or 1)
	end)
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
		self:add_hl_start((type(hl) == "table" and { bg = hl.fg }))
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

---@param hl? string
---@return Builder
function Builder:add_mode(hl)
	local mode_names = { -- change the strings if you like it vvvvverbose!
		n = "N",
		no = "N?",
		nov = "N?",
		noV = "N?",
		["no\22"] = "N?",
		niI = "Ni",
		niR = "Nr",
		niV = "Nv",
		nt = "Nt",
		v = "V",
		vs = "Vs",
		V = "V_",
		Vs = "Vs",
		["\22"] = "^V",
		["\22s"] = "^V",
		s = "S",
		S = "S_",
		["\19"] = "^S",
		i = "I",
		ic = "Ic",
		ix = "Ix",
		R = "R",
		Rc = "Rc",
		Rx = "Rx",
		Rv = "Rv",
		Rvc = "Rv",
		Rvx = "Rv",
		c = "C",
		cv = "Ex",
		r = "...",
		rm = "M",
		["r?"] = "?",
		["!"] = "!",
		t = "T",
	}

	local mode_colors = {
		n = "Error",
		i = "String",
		v = "Special",
		V = "Special",
		["\22"] = "Special",
		c = "Constant",
		s = "Statement",
		S = "Statement",
		["\19"] = "Statement",
		R = "Constant",
		r = "Constant",
		["!"] = "Error",
		t = "Error",
	}

	self:add(function()
		return "%(" .. mode_names[vim.fn.mode(1)] .. "%)"
	end, function()
		return { fg = highlight.get_highlight(mode_colors[vim.fn.mode(1)]).fg }
	end)
	return self
end

---@return string
function Builder:build()
	local res = ""
	for _, value in ipairs(self.statusline) do
		res = res .. value()
	end
	return res
end

return Builder
