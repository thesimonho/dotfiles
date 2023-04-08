local M = {
	"kiyoon/jupynium.nvim",
	enabled = true,
	build = "conda run --no-capture-output -n base pip install .",
	cmd = { "JupyniumStartAndAttachToServer", "JupyniumAttachToServer" },
}

function M.config()
	require("jupynium").setup({
		python_host = { "conda", "run", "--no-capture-output", "-n", "base", "python" },
		jupyter_command = "jupyter",
		auto_start_server = {
			enable = false,
			file_pattern = { "*.ju.*" },
		},
		-- Attach current nvim to the Jupynium server
		-- Without this step, you can't use :JupyniumStartSync
		-- Related command :JupyniumAttachToServer
		auto_attach_to_server = {
			enable = false,
			file_pattern = { "*.ju.*" },
		},
		-- Automatically open an Untitled.ipynb file on Notebook
		-- when you open a .ju.py file on nvim.
		-- Related command :JupyniumStartSync
		auto_start_sync = {
			enable = false,
			file_pattern = { "*.ju.*" },
		},
		-- Automatically keep filename.ipynb copy of filename.ju.py
		-- by downloading from the Jupyter Notebook server.
		-- This will overwrite the file without asking
		-- Related command :JupyniumDownloadIpynb
		auto_download_ipynb = true,
		-- Always scroll to the current cell.
		-- Related command :JupyniumScrollToCell
		autoscroll = {
			enable = true,
			mode = "always", -- "always" or "invisible"
			cell = {
				top_margin_percent = 20,
			},
		},
		use_default_keybindings = false,
		textobjects = {
			use_default_keybindings = false,
		},
		syntax_highlight = {
			enable = true,
		},
		-- Dim all cells except the current one
		-- Related command :JupyniumShortsightedToggle
		shortsighted = false,
	})
end

return M
