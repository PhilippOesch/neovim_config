---@class Config.Plugin.Build.Event.Data
---@field path string
---@field active boolean
---@field spec {name: string}

---@alias Config.InitFunction fun()

---@class Config.Plugin.Build.Event
---@field data Config.Plugin.Build.Event.Data
---
---@class Config.Plugin.Build
---@field plugin_name string
---@field kind string[]
---@field callback fun(ev: Config.Plugin.Build.Event)

---@class Config.Plugin
---@field deps Config.Plugin.Definition[]
---@field build Config.Plugin.Build|nil
---@field init Config.InitFunction|nil

---@alias Config.Plugin.Definition Config.Plugin|string|vim.pack.Spec

---@class Config.Plugin.Manager
---@field setup fun(plugins: (Config.Plugin|vim.pack.Spec|string)[])
---@field initialize Config.InitFunction

---@type Config.Plugin.Manager
local M = {}

---@type Config.InitFunction[]
local init_setups = {}

--- setup build hooks
--- @param build_definitions table<string, {kind: string[], callback: fun(ev: Config.Plugin.Build.Event)}>
local function setup_build_hooks(build_definitions)
	if next(build_definitions) then
		vim.api.nvim_create_autocmd("PackChanged", {
			callback = function(ev)
				local script = build_definitions[ev.data.spec.name]

				if not script or not vim.tbl_contains(script.kind, ev.data.kind) then
					return
				end

				if script and vim.tbl_contains(script.kind, ev.data.kind) then
					local ok, err = pcall(script.callback, ev)
					if not ok then
						vim.notify("Build failed for " .. ev.data.spec.name .. ": " .. err, vim.log.levels.ERROR)
					end
				end
			end,
		})
	end
end

--- recurstively resolve all vim packages and build definitions
---@param plugins Config.Plugin.Definition[]
---@param packages ((string|vim.pack.Spec)[])|nil
---@param build_definitions (table<string, {kind: string[], callback: fun(ev: Config.Plugin.Build.Event)}>)|nil
---@return (string|vim.pack.Spec)[], table<string, {kind: string[], callback: fun(ev: Config.Plugin.Build.Event)}>
local function resolve_plugin_config(plugins, packages, build_definitions)
	packages = packages or {}
	build_definitions = build_definitions or {}

	for _, plugin in ipairs(plugins) do
		if type(plugin) == "string" then
			table.insert(packages, plugin)
			goto continue
		elseif type(plugin) == "table" then
			if plugin.deps and type(plugin.deps) == "table" then
				resolve_plugin_config(plugin.deps, packages, build_definitions)
			elseif plugin.src then
				table.insert(packages, plugin)
			end

			if plugin.build and type(plugin.build) == table then
				build_definitions[plugin.build.plugin_name] = {
					kind = plugin.build.kind,
					callback = plugin.build.callback,
				}
			end

			if plugin.init and type(plugin.init) == "function" then
				table.insert(init_setups, plugin.init)
			end
		end

		::continue::
	end

	return packages, build_definitions
end

M.setup = function(plugins)
	if type(plugins) ~= "table" then
		error("setup() requires a table of plugins")
	end

	local packages, build_definitions = resolve_plugin_config(plugins)

	setup_build_hooks(build_definitions)

	vim.pack.add(packages, { confirm = false })
end

M.initialize = function()
	for _, plugin_init in ipairs(init_setups) do
		local ok, err = pcall(plugin_init)
		if not ok then
			vim.notify("Plugin init failed: " .. err, vim.log.levels.ERROR)
		end
	end
end

return M
