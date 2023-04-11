local M = {
	"kevinhwang91/nvim-hlslens",
	enabled = true,
	keys = { "/", "?" },
	command = { "HlSearchLensToggle", "HlSearchLensEnable" },
}

function M.config()
	require("hlslens").setup({
		auto_enable = true,
		enable_incsearch = true,
		calm_down = false,
		nearest_only = false,
		nearest_float_when = "auto",
		float_shadow_blend = 50,
		virt_priority = 100,
		override_lens = function(render, posList, nearest, idx, relIdx)
			local sfw = vim.v.searchforward == 1
			local indicator, text, chunks
			local absRelIdx = math.abs(relIdx)
			if absRelIdx > 1 then
				indicator = ("%d%s"):format(absRelIdx, sfw ~= (relIdx > 1) and "N(▲)" or "n(▼)")
			elseif absRelIdx == 1 then
				indicator = sfw ~= (relIdx == 1) and "N(▲)" or "n(▼)"
			else
				indicator = ""
			end

			local lnum, col = unpack(posList[idx])
			local cnt = #posList
			if nearest then
				if indicator ~= "" then
					text = ("   [ %s | %d/%d ]"):format(indicator, idx, cnt)
				else
					text = (" [ %d/%d ] "):format(idx, cnt) -- current line
				end
				chunks = { { " ", "Ignore" }, { text, "HlSearchLensNear" } }
			else
				text = ("   [ %s | %d/%d ]"):format(indicator, idx, cnt)
				chunks = { { " ", "Ignore" }, { text, "HlSearchLens" } }
			end
			render.setVirt(0, lnum - 1, col - 1, chunks, nearest)
		end,
	})
end

return M
