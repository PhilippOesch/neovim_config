---@class Todo.Win
---@field state Todo.State

local Win = {}
Win.__index = Win

---@return Todo.Win
function Win.new()
	local self = setmetatable({}, Win)
	self.state = {}
	return self
end

return Win
