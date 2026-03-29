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

---truncate a string
---@param title string|nil
---@param max_length number
---@return string
function M.trunc_str(title, max_length)
	if title ~= nil then
		local title_str = tostring(title)
		-- use vim.fn.strchars/strcharpart to handle multibyte characters if available
		if vim and vim.fn and vim.fn.strchars then
			if vim.fn.strchars(title_str) > max_length then
				return vim.fn.strcharpart(title_str, 0, max_length) .. "…"
			else
				return title_str
			end
		else
			if #title_str > max_length then
				return title_str:sub(1, max_length) .. "…"
			else
				return title_str
			end
		end
	end
	return ""
end

return M
