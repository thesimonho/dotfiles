local M = {
	"ThePrimeagen/refactoring.nvim",
	enabled = true,
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-lua/plenary.nvim" },
	event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	require("refactoring").setup()
end

return M
