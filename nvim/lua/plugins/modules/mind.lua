local M = {
	"phaazon/mind.nvim",
	cond = vim.g.vscode == nil,
	enabled = true,
	branch = "v2.2",
	dependencies = "nvim-lua/plenary.nvim",
	cmd = {
		"MindOpenMain",
		"MindOpenProject",
		"MindOpenSmartProject",
	},
}

function M.config()
	require("mind").setup({
		persistence = {
			state_path = vim.fn.stdpath("data") .. "/mind/mind.json",
			data_dir = vim.fn.stdpath("data") .. "/mind/data",
		},
	})
end

return M
