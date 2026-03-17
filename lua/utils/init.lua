local M = {}

---
---@param package string
function M.requireAll(package)
	local path = "/lua/" .. string.gsub(package, "%.", "/")

	local packages = {}

	for _, file in ipairs(vim.fn.readdir(vim.fn.stdpath("config") .. path, [[v:val =~ '\.lua$']])) do
		local pname = file:gsub("%.lua$", "")
		packages[pname] = require(package .. "." .. pname)
	end

    return packages
end

return M
