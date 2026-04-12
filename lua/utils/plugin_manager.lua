---@class Config.Plugin.Build.Event.Data
---@field path string
---@field active boolean
---@field spec {name: string}

---@class Config.Plugin.Build.Event
---@field data Config.Plugin.Build.Event.Data
---
---@class Config.Plugin.Build
---@field plugin_name string
---@field kind string[]
---@field callback fun(ev: Config.Plugin.Build.Event)

---@class Config.Plugin
---@field specs (string|vim.pack.Spec)[]
---@field build Config.Plugin.Build|nil
---@field init fun()

---@class Config.Plugin.Manager
---@field setup fun(plugins: (Config.Plugin|vim.pack.Spec|string)[])
---@field initialize fun()

---@type Config.Plugin.Manager
local M = {}

---@type Config.Plugin[]
local init_setups = {}

M.setup = function(plugins)
	---@type (string|vim.pack.Spec)[]
	local packages = {}

	local build_definitions = {}

	for _, plugin in ipairs(plugins) do
		if type(plugin) == "string" then
			table.insert(packages, plugin)
			goto continue
		elseif type(plugin) == "table" and plugin.src then
			table.insert(packages, plugin)
		else
			vim.list_extend(packages, plugin.specs)
			if plugin.build then
				build_definitions[plugin.build.plugin_name] = {
					kind = plugin.build.kind,
					callback = plugin.build.callback,
				}
			end
			table.insert(init_setups, plugin)
		end

		::continue::
	end

	vim.api.nvim_create_autocmd("PackChanged", {
		callback = function(ev)
			local script = build_definitions[ev.data.spec.name]
			if script and vim.tbl_contains(script.kind, ev.data.kind) then
				script.callback(ev)
			end
		end,
	})

	vim.pack.add(packages, { confirm = false })
end

M.initialize = function()
	for _, plugin in ipairs(init_setups) do
		plugin.init()
	end
end

return M
