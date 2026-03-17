local dap_available, dap = pcall(require, "dap")

local DAPMessages = {
	condition = function()
		return dap_available and dap.session()
	end,
	provider = function()
		return " " .. require("dap").status()
	end,
	hl = "Debug",
	-- see Click-it! section for clickable actions
}

return {
	Messages = DAPMessages,
}
