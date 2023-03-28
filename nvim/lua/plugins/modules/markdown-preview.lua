local M = {
	"iamcco/markdown-preview.nvim",
	cond = vim.g.vscode == nil,
	build = "cd app && npm install",
	enabled = true,
	ft = "markdown",
}

function M.config()
	--set to 1, nvim will open the preview window after entering the markdown buffer
	--default: 0
	vim.g.mkdp_auto_start = 0

	--set to 1, the nvim will auto close current preview window when change
	--from markdown buffer to another buffer
	--default: 1
	vim.g.mkdp_auto_close = 1

	--set to 1, the vim will refresh markdown when save the buffer or
	--leave from insert mode, default 0 is auto refresh markdown as you edit or
	--move the cursor
	--default: 0
	vim.g.mkdp_refresh_slow = 0

	--set to 1, the MarkdownPreview command can be use for all files,
	--by default it can be use in markdown file
	--default: 0
	vim.g.mkdp_command_for_global = 0

	--set to 1, preview server available to others in your network
	--by default, the server listens on localhost (127.0.0.1)
	--default: 0
	vim.g.mkdp_open_to_the_world = 0

	--use custom IP to open preview page
	--useful when you work in remote vim and preview on local browser
	--more detail see: https://github.com/iamcco/markdown-preview.nvim/pull/9
	--default empty
	vim.g.mkdp_open_ip = ""

	--specify browser to open preview page
	--for path with space
	--valid: `/path/with\ space/xxx`
	--invalid: `/path/with\\ space/xxx`
	--default: ''
	vim.g.mkdp_browser = ""

	--set to 1, echo preview page url in command line when open preview page
	--default is 0
	vim.g.mkdp_echo_preview_url = 0

	--a custom vim function name to open preview page
	--this function will receive url as param
	--default is empty
	vim.g.mkdp_browserfunc = ""

	--use a custom markdown style must be absolute path
	--like '/Users/username/markdown.css' or expand('~/markdown.css')
	vim.g.mkdp_markdown_css = ""

	--use a custom highlight style must absolute path
	--like '/Users/username/highlight.css' or expand('~/highlight.css')
	vim.g.mkdp_highlight_css = ""

	--use a custom port to start server or empty for random
	vim.g.mkdp_port = ""

	--preview page title
	--${name} will be replace with the file name
	vim.g.mkdp_page_title = "「${name}」"

	--recognized filetypes
	--these filetypes will have MarkdownPreview... commands
	vim.g.mkdp_filetypes = { "markdown" }

	--set default theme (dark or light)
	--By default the theme is define according to the preferences of the system
	vim.g.mkdp_theme = "dark"
end

return M
