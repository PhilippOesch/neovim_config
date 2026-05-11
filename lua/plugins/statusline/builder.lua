local Builder = {}
Builder.__index = Builder

---@class Builder
---@field statusline eval_fun[]
---@field new fun(): Builder
---@field add fun(self: Builder, fn: eval_fun, hl?: string): Builder
---@field add_filename fun(self: Builder): Builder
---@field add_align fun(self: Builder): Builder
---@field add_space fun(self: Builder, chars?: string, len?: integer): Builder
---@field add_surround fun(self: Builder, left: string, right: string, fn: eval_fun_builder, hl?:string): Builder
---@field add_mode fun(self: Builder, hl?:string): Builder
---@field build fun(self: Builder): string

---@alias eval_fun fun():string
---@alias eval_fun_builder fun(self: Builder)

---@return Builder
function Builder.new()
	local self = setmetatable({}, Builder)

	---@type eval_fun[]
	self.statusline = {}

	return self
end

function Builder:add_hl_start(hl)
	table.insert(self.statusline, function()
		return "%#" .. hl .. "#"
	end)
end
function Builder:add_hl_end()
	table.insert(self.statusline, function()
		return "%*"
	end)
end

---add new eval function
---@param fn eval_fun
---@param hl? string
---@return Builder
function Builder:add(fn, hl)
	if hl ~= nil then
		self:add_hl_start(hl)
		table.insert(self.statusline, fn)
		self:add_hl_end()
	else
		table.insert(self.statusline, fn)
	end
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
		self:add_hl_start(hl)
		self:add(function()
			return left
		end, hl)
		fn(self)
		self:add(function()
			return right
		end, hl)
		self:add_hl_end()
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
	end, mode_colors[vim.fn.mode(1)])
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
