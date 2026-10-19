---@type Config.Plugin
return {
	deps = {
		"https://github.com/nvim-neotest/nvim-nio",
		{ src = "https://github.com/lunarmodules/lua-mimetypes", version = "7c899be0c402067d11e50d802f0135ba64eccb51" },
		{ src = "https://github.com/manoelcampos/xml2lua", version = "b0d2b0b156b4e66078da2dc4b31d978daa69b3ef" },
		{ src = "https://github.com/rest-nvim/tree-sitter-http", version = "db8b4398de90b6d0b6c780aba96aaa2cd8e9202c" },
	},
	build = {
		plugin_name = "tree-sitter-http",
		kind = { "install", "update" },
		callback = function(ev)
			local root = ev.data.path
			local src = root .. "/src"
			local output = root .. "/parser/http.so"
			vim.fn.mkdir(root .. "/parser", "p")
			local linker = vim.uv.os_uname().sysname == "Darwin" and "-dynamiclib" or "-shared"
			local result = vim.system({ "cc", "-O2", "-fPIC", linker, "-I" .. src, src .. "/parser.c", "-o", output }, { text = true }):wait()
			if result.code ~= 0 then
				error("HTTP parser compilation failed; install a C compiler and retry :PackUpdate tree-sitter-http: " .. (result.stderr or ""))
			end
		end,
	},
	init = function()
		-- LuaRocks modules live at the repository root rather than under lua/.
		for _, module in ipairs({ "mimetypes.lua", "xml2lua.lua" }) do
			local paths = vim.api.nvim_get_runtime_file(module, false)
			if #paths ~= 1 then
				error("Missing rest.nvim dependency " .. module .. "; run :PackUpdate")
			end
			local root = vim.fs.dirname(paths[1])
			package.path = package.path .. ";" .. root .. "/?.lua;" .. root .. "/?/init.lua"
		end
		for _, module in ipairs({ "nio", "fidget", "mimetypes", "xml2lua", "xmlhandler.tree" }) do
			require(module)
		end
		-- v3.13.0 ignores cookies.enable in its jar paths; both hooks are needed.
		vim.g.rest_nvim = {
			cookies = {
				enable = false,
				path = vim.fn.stdpath("state") .. "/rest-nvim-no-cookies.jar",
			},
		}
		local group = vim.api.nvim_create_augroup("UserRestNoCookies", { clear = true })
		local cookie_policy = require("plugins.rest_cookie_policy")
		vim.api.nvim_create_autocmd("User", {
			group = group,
			pattern = "RestRequestPre",
			callback = cookie_policy.on_request,
		})
		vim.api.nvim_create_autocmd("User", {
			group = group,
			pattern = "RestResponsePre",
			callback = cookie_policy.on_response,
		})
		-- Rest checks dependencies while loading, before the wrapper's add completes.
		vim.pack.add({
			{ src = "https://github.com/rest-nvim/rest.nvim", version = "de9726ab956e30202aafbcdea83c1d6bffe54227" },
		}, { confirm = false })
		-- :Rest last skips pre-request validation; an autocmd error cannot stop curl.
		require("rest-nvim.commands").register_subcommand("last", {
			impl = function()
				error(":Rest last is disabled: use :Rest run to reparse and validate the request")
			end,
		})
		vim.api.nvim_create_autocmd("FileType", {
			group = group,
			pattern = "http",
			callback = function(ev)
				local path = require("plugins.rest_guard").env_path(ev.buf)
				if path then
					vim.b[ev.buf]._rest_nvim_env_file = path
				end
			end,
		})
	end,
}
