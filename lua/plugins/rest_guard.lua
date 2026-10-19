-- Pre-request script errors abort parsing before rest.nvim starts curl (v3.13.0).
local M = {}

function M.env_path(buf)
	local file = vim.api.nvim_buf_get_name(buf or 0)
	if file == "" then
		return nil
	end
	local marker = vim.fs.find(".env.example", { path = vim.fs.dirname(file), upward = true, type = "file" })[1]
	return marker and (vim.fs.dirname(marker) .. "/.env") or nil
end

function M.check(request, keys)
	local path = M.env_path(0)
	assert(path and vim.b._rest_nvim_env_file == path, "Select the workspace root .env before sending")
	local ok, values = require("rest-nvim.parser.dotenv").parse(path)
	assert(ok and values, "Missing workspace root .env")
	for _, key in ipairs(keys) do
		local value = values[key]
		assert(type(value) == "string" and value:match("%S") and request.variables.get(key) == value,
			"Missing or stale " .. key .. " in the workspace .env")
	end
	assert(values.BASE:match("^https?://[^/]+$"), "BASE must be an explicit approved HTTP(S) origin")
end

return M
