local M = {
	"ellisonleao/glow.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	cmd = "Glow",
}

function M.config()
	require("glow").setup({
		border = "shadow", -- floating window border config
		style = "dark", -- filled automatically with your current editor background,
		pager = true,
		width_ratio = 0.8, -- maximum width of the Glow window compared to the nvim window size (overrides `width`)
		height_ratio = 0.8,
	})
end
return M
