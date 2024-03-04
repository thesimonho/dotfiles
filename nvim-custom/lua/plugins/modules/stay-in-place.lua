local M = {
    "gbprod/stay-in-place.nvim",
    enabled = true,
    event = { "BufReadPost", "BufNewFile" },
}

function M.config()
	require("stay-in-place").setup({
		set_keymaps = true,
		preserve_visual_selection = true,
	})
end

return M
