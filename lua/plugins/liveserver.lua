---@type Config.Plugin
return {
	init = function()
		---@type vim.SystemObj|nil
		local current_job = nil

		local function stop_server()
			if current_job then
				local job = current_job
				pcall(function()
					job:kill()
				end)
				current_job = nil
				vim.notify("Live servers stopped", vim.log.levels.INFO)
			else
				vim.notify("No live server running", vim.log.levels.WARN)
			end
		end

		local function start_server()
			if vim.bo.filetype ~= "html" then
				vim.notify("LiveServer start is only available for HTML files", vim.log.levels.ERROR)
				return
			end

			if vim.fn.executable("live-server") == 0 then
				vim.notify("live-server not found. Install it via: npm i -g live-server", vim.log.levels.ERROR)
				return
			end

			-- Only one server at a time; kill any existing instance first.
			if current_job then
				local old_job = current_job
				pcall(function()
					old_job:kill()
				end)
				pcall(function()
					old_job:wait()
				end)
				if current_job == old_job then
					current_job = nil
				end
			end

			local filepath = vim.fn.expand("%:p")
			local job = vim.system({ "live-server", filepath }, {}, function()
				if current_job == job then
					current_job = nil
				end
			end)
			current_job = job

			vim.notify("Live server started", vim.log.levels.INFO)
		end

		vim.api.nvim_create_user_command("LiveServer", function(opts)
			local sub = opts.args:lower()
			if sub == "start" then
				start_server()
			elseif sub == "stop" then
				stop_server()
			else
				vim.notify("Unknown LiveServer command: " .. sub, vim.log.levels.ERROR)
			end
		end, {
			nargs = 1,
			complete = function()
				return { "start", "stop" }
			end,
			desc = "Start or stop live-server for the current HTML buffer",
		})
	end,
}
