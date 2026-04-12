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
---@field new fun(plugins: (Config.Plugin|vim.pack.Spec|string)[])
---@field init fun(self: Config.Plugin.Manager)

local M = {}
local Manager = {}
Manager.__index = Manager

--- resolve plugin config recursively (collects packages, build defs, init hooks)
---@param plugins Config.Plugin.Definition[]
---@param packages ((string|vim.pack.Spec)[])|nil
---@param build_definitions (table<string, {kind: string[], callback: fun(ev: Config.Plugin.Build.Event)}>)|nil
---@param init_setups Config.InitFunction[]|nil
---@return (string|vim.pack.Spec)[], table<string, {kind: string[], callback: fun(ev: Config.Plugin.Build.Event)}>, Config.InitFunction[]
local function resolve_plugin_config(plugins, packages, build_definitions, init_setups)
	packages = packages or {}
	build_definitions = build_definitions or {}
	init_setups = init_setups or {}

	for _, plugin in ipairs(plugins) do
		if type(plugin) == "string" then
			table.insert(packages, plugin)
			goto continue
		elseif type(plugin) == "table" then
			if plugin.deps and type(plugin.deps) == "table" then
				resolve_plugin_config(plugin.deps, packages, build_definitions, init_setups)
			elseif plugin.src then
				table.insert(packages, plugin)
			end

			if plugin.build and type(plugin.build) == "table" then
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

	return packages, build_definitions, init_setups
end

--- Create autocmd for PackChanged that will invoke build callbacks from build_definitions
---@param build_definitions table<string, {kind: string[], callback: fun(ev: Config.Plugin.Build.Event)}>
local function setup_build_hooks(build_definitions)
	if next(build_definitions) then
		vim.api.nvim_create_autocmd("PackChanged", {
			callback = function(ev)
				local script = build_definitions[ev.data.spec.name]

				if not script or not vim.tbl_contains(script.kind, ev.data.kind) then
					return
				end

				local ok, err = pcall(script.callback, ev)
				if not ok then
					vim.notify("Build failed for " .. ev.data.spec.name .. ": " .. err, vim.log.levels.ERROR)
				end
			end,
		})
	end
end

--- Construct a new plugin manager and perform initial setup (collect inits, hooks, install packages)
---@param plugins (Config.Plugin|vim.pack.Spec|string)[]
---@return Config.Plugin.Manager
function M.new(plugins)
	if type(plugins) ~= "table" then
		error("new() requires a table of plugins")
	end

	local self = setmetatable({}, Manager)

	-- collect packages, build_definitions and init hooks
	local packages, build_definitions, init_setups = resolve_plugin_config(plugins)

	self.packages = packages
	self.build_definitions = build_definitions
	self.init_setups = init_setups

	-- setup autocmds for builds
	setup_build_hooks(self.build_definitions)

	-- add packages
	vim.pack.add(self.packages, { confirm = false })

	return self
end

--- Call all plugin init hooks collected during construction
function Manager:init()
	for _, plugin_init in ipairs(self.init_setups or {}) do
		local ok, err = pcall(plugin_init)
		if not ok then
			vim.notify("Plugin init failed: " .. err, vim.log.levels.ERROR)
		end
	end
end

return M
