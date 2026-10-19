-- rest.nvim v3.13.0 ignores cookies.enable in its jar paths.
local M = {}

function M.on_request()
	local req = _G.rest_request
	req.cookies = {}
	req.headers.cookie = nil
end

function M.on_response()
	_G.rest_response.headers["set-cookie"] = nil
end

return M
