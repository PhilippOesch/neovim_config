local function get_default_branch()
	local out = vim.fn.system("git remote show origin | grep 'HEAD branch' | cut -d' ' -f5 2>/dev/null")
	out = out:gsub("%s+$", "") -- trim trailing whitespace/newlines
	if out == "" then
		return "main"
	end
	return out
end

local function get_diff_code_review_prompt()
	local default_branch = get_default_branch()
	local input_string = string.format("Target branch for merge base diff (default: %s) ", default_branch)
	local target_branch = vim.fn.input(input_string, default_branch)

	return vim.fn.system("git diff --no-ext-diff --merge-base " .. target_branch)
end

return {
	diff = function(_)
		return get_diff_code_review_prompt()
	end,
}
