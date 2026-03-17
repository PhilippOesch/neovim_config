local conditions = require("heirline.conditions")
local oil_available, oilnvim = pcall(require, "oil")
local utils = require("heirline.utils")

local Oil = {
	condition = function()
		return oil_available
	end,
	provider = function(self)
		local pathFormat = ":p:~:."
		local dir = oilnvim.get_current_dir()
		local bufName
		if dir then
			bufName = vim.fn.fnamemodify(dir, pathFormat)
		else
			bufName = vim.api.nvim_buf_get_name(0)
		end

		if bufName == "" then
			return " ./"
		end
		return " " .. bufName
	end,
	hl = { fg = "blue" },
}

local OilPreview = {
	condition = function(self)
		return vim.bo.filetype == "oil_preview"
	end,
	{
		provider = "[Y]",
		hl = { fg = "cyan" },
	},
	{
		provider = "es",
	},
	{ provider = " " },
	{
		provider = "[N]",
		hl = { fg = "red" },
	},
	{
		provider = "o",
	},
}

local OilBlock = {
	fallthrough = false,
	condition = function()
		return oil_available and vim.bo.filetype == "oil"
	end,
	{ -- An inactive winbar for regular files
		condition = function()
			return not conditions.is_active()
		end,
		utils.insert({ hl = { fg = "gray", force = true }, Oil }),
	},
	-- A winbar for regular files
	Oil,
}

return {
	OilBlock = OilBlock,
	OilPreview = OilPreview,
}
