local MiniTest = require("mini.test")
local T = MiniTest.new_set()
local guard = require("plugins.rest_guard")
local eq = MiniTest.expect.equality

local function fixture()
	local root = vim.fn.tempname()
	vim.fn.mkdir(root .. "/babtecq", "p")
	vim.fn.writefile({ "BASE='http://127.0.0.1:1234'" }, root .. "/.env")
	vim.fn.writefile({ "BASE='https://REPLACE-WITH-APPROVED-TEST-HOST'" }, root .. "/.env.example")
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, root .. "/babtecq/auth.http")
	vim.api.nvim_set_current_buf(buf)
	vim.b._rest_nvim_env_file = root .. "/.env"
	return root, buf
end

T["selects root .env from nested file, not cwd"] = function()
	local root, buf = fixture()
	eq(guard.env_path(buf), root .. "/.env")
	vim.api.nvim_buf_delete(buf, { force = true })
	vim.fn.delete(root, "rf")
end

T["refuses a missing or stale credential before the request runner"] = function()
	local root, buf = fixture()
	local old = package.loaded["rest-nvim.parser.dotenv"]
	local values = { BASE = "http://127.0.0.1:1234", ACCESS_TOKEN = "fixture-token" }
	package.loaded["rest-nvim.parser.dotenv"] = { parse = function() return true, values end }
	local parsed = vim.deepcopy(values)
	local request = { variables = { get = function(key) return parsed[key] end } }
	local keys = { "BASE", "ACCESS_TOKEN" }
	eq(pcall(guard.check, request, keys), true)
	values.ACCESS_TOKEN = nil
	eq(pcall(guard.check, request, keys), false)
	values.ACCESS_TOKEN = "fixture-token"
	parsed.ACCESS_TOKEN = "stale-fixture-token"
	eq(pcall(guard.check, request, keys), false)
	parsed.ACCESS_TOKEN = values.ACCESS_TOKEN
	vim.b._rest_nvim_env_file = "/tmp/other.env"
	eq(pcall(guard.check, request, keys), false)
	package.loaded["rest-nvim.parser.dotenv"] = old
	vim.api.nvim_buf_delete(buf, { force = true })
	vim.fn.delete(root, "rf")
end

T["request event strips cookies on repeated calls with the same request"] = function()
	local policy = require("plugins.rest_cookie_policy")
	local request = { cookies = { { name = "fixture" } }, headers = { cookie = { "fixture=1" } } }
	_G.rest_request = request
	for _ = 1, 2 do
		policy.on_request()
		eq(request.cookies, {})
		eq(request.headers.cookie, nil)
		request.cookies = { { name = "fixture" } }
		request.headers.cookie = { "fixture=2" }
	end
	policy.on_request()
	eq(request.cookies, {})
	eq(request.headers.cookie, nil)
	_G.rest_request = nil
end

T["response event strips Set-Cookie"] = function()
	local policy = require("plugins.rest_cookie_policy")
	_G.rest_response = { headers = { ["set-cookie"] = { "fixture=1" } } }
	policy.on_response()
	eq(_G.rest_response.headers["set-cookie"], nil)
	_G.rest_response = nil
end

return T
