local M = {
	"vuki656/package-info.nvim",
	enabled = false,
    cond = vim.g.vscode == nil,
	dependencies = "MunifTanjim/nui.nvim",
	ft = "json",
}

function M.config()
	require("package-info").setup({
		colors = {
			up_to_date = "#3C4048", -- Text color for up to date dependency virtual text
			outdated = "#d19a66", -- Text color for outdated dependency virtual text
		},
		icons = {
			enable = true, -- Whether to display icons
			style = {
				up_to_date = "|  ", -- Icon for up to date dependencies
				outdated = "|  ", -- Icon for outdated dependencies
			},
		},
		autostart = true, -- Whether to autostart when `package.json` is opened
		hide_up_to_date = true, -- It hides up to date versions when displaying virtual text
		hide_unstable_versions = true, -- It hides unstable versions from version list e.g next-11.1.3-canary3
		package_manager = "npm",
	})
	require("telescope").load_extension("package_info")
end

return M
