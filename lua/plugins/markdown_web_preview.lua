-- Render Markdown to a standalone HTML file and open it in the browser.
--
-- There is no local Markdown toolchain to install: the generated page carries
-- its source as a base64 payload and converts it client-side with marked +
-- highlight.js from a CDN. The md-preview/ stylesheets are inlined, so the
-- output is a single self-contained file.

local CDN_MARKED = "https://cdn.jsdelivr.net/npm/marked@14/marked.min.js"
local CDN_HIGHLIGHT = "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.10.0/build/highlight.min.js"

-- Reused from the markdown-preview.nvim setup; both expect `.markdown-body`
-- content inside `#page-ctn`, and `[data-theme="dark"]` on the root element.
local STYLESHEETS = { "md-preview/style.css", "md-preview/highlight.css" }

local TEMPLATE = [[<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<base href="{{base}}">
<title>{{title}}</title>
<style>
{{style}}
</style>
</head>
<body>
<div id="page-ctn"><article class="markdown-body" id="content"></article></div>
<script id="markdown-source" type="application/octet-stream">{{payload}}</script>
<script src="{{marked}}"></script>
<script src="{{highlight}}"></script>
<script>
(function () {
  const encoded = document.getElementById("markdown-source").textContent.replace(/\s+/g, "");
  const bytes = Uint8Array.from(atob(encoded), (ch) => ch.charCodeAt(0));
  const markdown = new TextDecoder("utf-8").decode(bytes);

  const content = document.getElementById("content");
  marked.setOptions({ gfm: true });
  content.innerHTML = marked.parse(markdown);

  // marked dropped heading ids in v5; add them back so in-page links work.
  const taken = new Set();
  content.querySelectorAll("h1, h2, h3, h4, h5, h6").forEach((heading) => {
    // \w is ASCII-only, so match letters/digits by Unicode property instead --
    // otherwise "ünïcode" would slug to "ncode".
    const base = heading.textContent.trim().toLowerCase()
      .replace(/[^\p{L}\p{N}\- ]+/gu, "")
      .replace(/\s+/g, "-") || "section";
    let slug = base;
    for (let n = 1; taken.has(slug); n += 1) slug = base + "-" + n;
    taken.add(slug);
    heading.id = slug;
  });

  content.querySelectorAll("li > input[type=checkbox]").forEach((box) => {
    box.parentElement.classList.add("task-list-item");
  });

  content.querySelectorAll("pre code").forEach((block) => hljs.highlightElement(block));
})();
</script>
</body>
</html>
]]

---Read a whole file, or nil when it cannot be opened.
---@param path string
---@return string|nil
local function read_file(path)
	local fd = io.open(path, "rb")
	if not fd then
		return nil
	end
	local content = fd:read("*a")
	fd:close()
	return content
end

---@param text string
---@return string
local function escape_html(text)
	return (
		text:gsub("[&<>\"']", {
			["&"] = "&amp;",
			["<"] = "&lt;",
			[">"] = "&gt;",
			['"'] = "&quot;",
			["'"] = "&#39;",
		})
	)
end

---Fill `{{key}}` placeholders. Values are substituted verbatim, so callers are
---responsible for escaping them for their target context.
---@param template string
---@param values table<string, string>
---@return string
local function render_template(template, values)
	return (template:gsub("{{(%w+)}}", function(key)
		return values[key] or ""
	end))
end

---@param path string
---@return string
local function encode_url_path(path)
	return (path:gsub("[^%w%-%._~/:]", function(char)
		return string.format("%%%02X", string.byte(char))
	end))
end

---Translate an absolute path into a URL the user's browser can open. Under WSL
---the browser is a Windows process, so it needs the Windows form of the path
---(normally a \\wsl.localhost UNC path).
---@param path string
---@return string
local function to_browser_url(path)
	if vim.fn.has("wsl") == 0 then
		return "file://" .. encode_url_path(path)
	end

	local windows_path = vim.trim(vim.fn.system({ "wslpath", "-w", path }))
	if vim.v.shell_error ~= 0 or windows_path == "" then
		return "file://" .. encode_url_path(path)
	end

	local url = (windows_path:gsub("\\", "/"))
	if url:sub(1, 2) == "//" then
		-- //wsl.localhost/Distro/tmp/x.html -> file://wsl.localhost/Distro/tmp/x.html
		return "file:" .. encode_url_path(url)
	end
	-- C:/Users/... -> file:///C:/Users/...
	return "file:///" .. encode_url_path(url)
end

---Command that hands `url` to the default browser, plus the directory it should
---run from.
---@param url string
---@return string[]|nil, string|nil
local function browser_command(url)
	if vim.fn.has("wsl") == 1 then
		local cmd = vim.fn.exepath("cmd.exe")
		if cmd == "" and vim.uv.fs_stat("/mnt/c/Windows/System32/cmd.exe") then
			cmd = "/mnt/c/Windows/System32/cmd.exe"
		end
		if cmd ~= "" then
			-- `start` reads its first quoted argument as a window title, hence
			-- the empty string. cwd keeps cmd.exe from warning about the UNC
			-- working directory.
			return { cmd, "/c", "start", "", url }, "/mnt/c"
		end
	end

	if vim.fn.has("mac") == 1 then
		return { "open", url }, nil
	end

	if vim.fn.executable("xdg-open") == 1 then
		return { "xdg-open", url }, nil
	end

	return nil, nil
end

---@param title string
---@param markdown string
---@param base_url string
---@return string
local function build_html(title, markdown, base_url)
	local styles = {}
	for _, name in ipairs(STYLESHEETS) do
		local css = read_file(vim.fs.joinpath(vim.fn.stdpath("config"), name))
		if css then
			table.insert(styles, css)
		end
	end

	return render_template(TEMPLATE, {
		title = escape_html(title),
		base = base_url,
		style = table.concat(styles, "\n"),
		payload = vim.base64.encode(markdown),
		marked = CDN_MARKED,
		highlight = CDN_HIGHLIGHT,
	})
end

---@class MarkdownWebPreview.Source
---@field markdown string
---@field name string
---@field dir string

---An explicit path argument if given, otherwise the current buffer -- so
---unsaved edits show up in the preview.
---@param arg string
---@return MarkdownWebPreview.Source|nil
local function resolve_source(arg)
	if arg ~= "" then
		local path = vim.fn.fnamemodify(vim.fn.expand(arg), ":p")
		local content = read_file(path)
		if not content then
			vim.notify("Cannot read Markdown file: " .. path, vim.log.levels.ERROR)
			return nil
		end
		return { markdown = content, name = vim.fs.basename(path), dir = vim.fs.dirname(path) }
	end

	if vim.bo.filetype ~= "markdown" then
		vim.notify("PreviewMarkdown needs a markdown buffer, or a file path argument", vim.log.levels.ERROR)
		return nil
	end

	local buf_name = vim.api.nvim_buf_get_name(0)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	return {
		markdown = table.concat(lines, "\n"),
		name = buf_name ~= "" and vim.fs.basename(buf_name) or "[No Name]",
		dir = buf_name ~= "" and vim.fs.dirname(buf_name) or assert(vim.uv.cwd()),
	}
end

---@param arg string
local function preview(arg)
	local source = resolve_source(arg)
	if not source then
		return
	end

	local out_dir = vim.fs.joinpath(vim.fn.stdpath("cache"), "md-preview")
	vim.fn.mkdir(out_dir, "p")

	-- One stable file per source: re-running the command only needs a browser
	-- refresh instead of piling up tabs and temp directories.
	local stem = source.name:gsub("%.%w+$", ""):gsub("[^%w%-_]", "_")
	local digest = vim.fn.sha256(source.dir .. "/" .. source.name):sub(1, 8)
	local out_path = vim.fs.joinpath(out_dir, stem .. "-" .. digest .. ".html")

	-- Relative images and links in the Markdown resolve against the source
	-- directory, not the cache directory the HTML lives in.
	local base_url = to_browser_url(source.dir)
	if not base_url:match("/$") then
		base_url = base_url .. "/"
	end

	local fd, open_err = io.open(out_path, "w")
	if not fd then
		vim.notify("Could not write preview: " .. tostring(open_err), vim.log.levels.ERROR)
		return
	end
	fd:write(build_html(source.name, source.markdown, base_url))
	fd:close()

	local cmd, cwd = browser_command(to_browser_url(out_path))
	if not cmd then
		vim.notify("No browser opener found (tried cmd.exe, open, xdg-open)", vim.log.levels.ERROR)
		return
	end

	vim.system(cmd, { cwd = cwd, text = true }, function(result)
		if result.code ~= 0 then
			vim.schedule(function()
				vim.notify(
					"Browser command failed (" .. result.code .. "): " .. (result.stderr or ""),
					vim.log.levels.ERROR
				)
			end)
		end
	end)

	vim.notify("Markdown preview: " .. out_path, vim.log.levels.INFO)
end

---@type Config.Plugin
return {
	init = function()
		vim.api.nvim_create_user_command("PreviewMarkdown", function(opts)
			preview(opts.args)
		end, {
			nargs = "?",
			complete = "file",
			desc = "Render Markdown to HTML and open it in the browser",
		})

		vim.keymap.set("n", "<leader>mb", "<cmd>PreviewMarkdown<CR>", {
			noremap = true,
			desc = "Preview Markdown in Browser",
		})
	end,
}
