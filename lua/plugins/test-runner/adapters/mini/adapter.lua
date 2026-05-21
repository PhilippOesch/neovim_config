---@class MiniTestAdapter: test_runner.Adapter
local M = {
	patterns = { "test_.*%.lua$" },
	parser = require("plugins.test-runner.adapters.mini.parser"),
}

local known_scripts = {
	"scripts/minimal_init.lua",
	"scripts/minitest.lua",
	"scripts/test_init.lua",
}

M.get_config = function(path)
	local dir = path
	local root = "/"
	local home = os.getenv("HOME") or ""

	-- Look for known init scripts
	while dir and dir ~= "" and dir ~= root and dir ~= home do
		for _, name in ipairs(known_scripts) do
			local script_path = dir .. "/" .. name
			if vim.fn.filereadable(script_path) == 1 then
				return { cwd = dir, init_script = script_path }
			end
		end

		local parent = vim.fn.fnamemodify(dir, ":h")
		if parent == dir then
			break
		end
		dir = parent
	end

	-- Fallback: look for .git + deps/mini.nvim
	dir = path
	while dir and dir ~= "" and dir ~= root and dir ~= home do
		local has_git_dir = vim.fn.finddir(".git", dir .. "/") ~= ""
		local has_git_file = vim.fn.filereadable(dir .. "/.git") == 1
		if has_git_dir or has_git_file then
			if vim.fn.isdirectory(dir .. "/deps/mini.nvim") == 1 then
				return { cwd = dir, init_script = nil }
			end
			break
		end
		local parent = vim.fn.fnamemodify(dir, ":h")
		if parent == dir then
			break
		end
		dir = parent
	end

	return nil
end

M.get_cwd = function(path)
	local config = M.get_config(path)
	if config and config.cwd then
		return config.cwd
	end
	return nil
end

---Generate a temp runner script and optionally a fallback init script.
---@param config table
---@param opts {filepath: string}
---@return table|nil
M.get_context = function(config, opts)
	local runner_script = vim.fn.tempname() .. ".lua"

	local runner_content = string.format(
		[[
local MiniTest = require('mini.test')

local ok, err = pcall(MiniTest.run_file, %q, {
  execute = {
    reporter = {
      start = function(cases) end,
      update = function(case_num) end,
      finish = function()
        local all_cases = MiniTest.current.all_cases
        if #all_cases == 0 then
          io.stdout:write(vim.json.encode({ ok = false, error = "No test cases found. Check that the file is a valid Mini.test file." }) .. "\n")
        else
          local cases = {}
          for _, case in ipairs(all_cases) do
            table.insert(cases, {
              desc = case.desc,
              state = case.exec and case.exec.state or nil,
              fails = case.exec and case.exec.fails or {},
              notes = case.exec and case.exec.notes or {},
              args = case.args,
            })
          end
          io.stdout:write(vim.json.encode({ ok = true, cases = cases }) .. "\n")
        end
        vim.cmd('qa!')
      end,
    },
    stop_on_error = false,
  }
})

if not ok then
  io.stdout:write(vim.json.encode({ ok = false, error = tostring(err) }) .. "\n")
  vim.cmd('qa!')
end
]],
		opts.filepath
	)

	local file = io.open(runner_script, "w")
	if not file then
		vim.notify("Mini.test adapter: failed to write runner script", vim.log.levels.ERROR)
		return nil
	end
	file:write(runner_content)
	file:close()

	local init_script = config.init_script
	local generated_init = false

	if not init_script then
		-- Generate fallback init script pointing to deps/mini.nvim
		init_script = vim.fn.tempname() .. ".lua"
		local init_content = "vim.cmd('set rtp+="
			.. config.cwd
			.. "/deps/mini.nvim')\n"
			.. "require('mini.test').setup()\n"

		local init_file = io.open(init_script, "w")
		if not init_file then
			vim.fn.delete(runner_script)
			vim.notify("Mini.test adapter: failed to write fallback init script", vim.log.levels.ERROR)
			return nil
		end
		init_file:write(init_content)
		init_file:close()
		generated_init = true
	end

	return {
		runner_script = runner_script,
		init_script = init_script,
		generated_init = generated_init,
		filepath = opts.filepath,
	}
end

---@param config table
---@param opts {filepath: string}
---@param context table|nil
---@return table|nil
M.get_cmd = function(config, opts, context)
	if not context then
		return nil
	end
	return {
		"nvim",
		"--headless",
		"--noplugin",
		"-u",
		context.init_script,
		"-c",
		"luafile " .. context.runner_script,
	}
end

---Clean up generated temp files.
---@param obj vim.SystemCompleted
---@param context table
---@return string|nil, string|nil
M.post_process = function(obj, context)
	if context then
		if context.runner_script then
			vim.fn.delete(context.runner_script)
		end
		if context.generated_init and context.init_script then
			vim.fn.delete(context.init_script)
		end
	end
	return obj.stdout, nil
end

return M
