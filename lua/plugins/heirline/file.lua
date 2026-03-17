local utils = require("heirline.utils")

local FileNameBlock = {
	-- let's first set up some attributes needed by this component and its children
	init = function(self)
		self.filetype = vim.bo.filetype
		self.filename = vim.api.nvim_buf_get_name(0)
	end,
}

local custom_icons = {
	codecompanion = { icon = "✨", icon_color = "#fddf3b" },
	oil = { icon = "", icon_color = "blue" },
}

local web_icons_available, web_icons = pcall(require, "nvim-web-devicons")
--
-- We can now define some children separately and add them later
--
local FileIcon = {
	condition = function()
		return web_icons_available
	end,
	init = function(self)
		if custom_icons[self.filetype] ~= nil then
			local data = custom_icons[self.filetype]
			self.icon = data.icon
			self.icon_color = data.icon_color
			return
		end
		local filename = self.filename
		local extension = vim.fn.fnamemodify(filename, ":e")
		self.icon, self.icon_color = web_icons.get_icon_color(filename, extension, { default = true })
	end,
	provider = function(self)
		return self.icon and (self.icon .. " ")
	end,
	hl = function(self)
		return { fg = self.icon_color }
	end,
}

local FileName = {
	init = function(self)
		self.lfilename = vim.fn.fnamemodify(self.filename, ":.")
		if self.lfilename == "" then
			self.lfilename = "[No Name]"
		end
	end,
	hl = { fg = "blue" },

	flexible = 2,

	{
		provider = function(self)
			return self.lfilename
		end,
	},
	{
		provider = function(self)
			return vim.fn.pathshorten(self.lfilename)
		end,
	},
}

local FileFlags = {
	{
		condition = function()
			return vim.bo.modified
		end,
		provider = "[+]",
		hl = { fg = "green" },
	},
	{
		condition = function()
			return not vim.bo.modifiable or vim.bo.readonly
		end,
		provider = "",
		hl = { fg = "orange" },
	},
}

-- Now, let's say that we want the filename color to change if the buffer is
-- modified. Of course, we could do that directly using the FileName.hl field,
-- but we'll see how easy it is to alter existing components using a "modifier"
-- component

local FileNameModifer = {
	hl = function()
		if vim.bo.modified then
			-- use `force` because we need to override the child's hl foreground
			return { fg = "cyan", bold = true, force = true }
		end
	end,
}

-- let's add the children to our FileNameBlock component
FileNameBlock = utils.insert(
	FileNameBlock,
	FileIcon,
	utils.insert(FileNameModifer, FileName), -- a new table where FileName is a child of FileNameModifier
	FileFlags,
	{ provider = "%<" } -- this means that the statusline is cut here when there's not enough space
)

local FileType = utils.insert({
	init = function(self)
		self.filetype = vim.bo.filetype
		self.filename = vim.api.nvim_buf_get_name(0)
	end,
	utils.insert(FileIcon, {
		provider = function(self)
			return self.filetype
		end,
	}),
	hl = { fg = utils.get_highlight("Type").fg, bold = true },
})

local FileFormat = {
	provider = function()
		local fmt = vim.bo.fileformat
		return fmt ~= "unix" and fmt:upper()
	end,
}

return {
	Name = FileName,
	Format = FileFormat,
	NameBlock = FileNameBlock,
	Type = FileType,
	Flags = FileFlags,
}
