local Builder = {}
Builder.__index = Builder

---@class Builder
---@field statusline eval_fun[]

---@alias eval_fun fun():string
---@alias eval_fun_builder fun(self: Builder)

---@return Builder
function Builder.new()
	local self = setmetatable({}, Builder)

	---@type eval_fun[]
	self.statusline = {}

	return self
end

---add new eval function
---@param fn eval_fun
---@return Builder
function Builder:add(fn)
	table.insert(self.statusline, fn)
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

---@param hl string
---@param fn eval_fun_builder
---@return Builder
function Builder:add_hl(hl, fn)
	self:add(function()
		return "%#" .. hl .. "#"
	end)
	fn(self)
	self:add(function()
		return "%*"
	end)
	return self
end

---@param left string
---@param right string
---@param fn eval_fun_builder
---@return Builder
function Builder:add_surround(left, right, fn)
	self:add(function()
		return left
	end)
	fn(self)
	self:add(function()
		return right
	end)
	return self
end

---@return Builder
function Builder:add_mode()
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

	self:add(function()
		return "%(" .. mode_names[vim.fn.mode(1)] .. "%)"
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
