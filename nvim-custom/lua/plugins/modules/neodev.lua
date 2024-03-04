local M = {
	"folke/neodev.nvim",
	enabled = true,
	cond = vim.g.vscode == nil,
	priority = 500,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"nvim-neotest/neotest-python",
		"rouge8/neotest-rust",
	},
	lazy = false,
}

function M.config()
	require("neodev").setup({
		library = {
			enabled = true, -- when not enabled, neodev will not change any settings to the LSP server
			-- these settings will be used for your Neovim config directory
			runtime = true, -- runtime path
			types = true, -- full signature, docs and completion of vim.api, vim.treesitter, vim.lsp and others
			plugins = { "nvim-treesitter", "plenary.nvim", "telescope.nvim", "neotest" },
		},
		setup_jsonls = true, -- configures jsonls to provide completion for project specific .luarc.json files
		-- for your Neovim config directory, the config.library settings will be used as is
		-- for plugin directories (root_dirs having a /lua directory), config.library.plugins will be disabled
		-- for any other directory, config.library.enabled will be set to false
		override = function(root_dir, options) end,
		lspconfig = true,
		pathStrict = true,
	})
end

return M
