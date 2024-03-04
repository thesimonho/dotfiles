local M = {
	"ggandor/leap.nvim",
	enabled = true,
	dependencies = "tpope/vim-repeat",
	event = { "BufRead", "BufNewFile" },
}

function M.config()
	require("leap").opts.safe_labels = { "s", "f", "n", "t" }
	require("leap").opts.labels = {
		"s",
		"f",
		"n",
		"j",
		"k",
		"l",
		"h",
		"d",
		"w",
		"e",
		"m",
		"b",
		"t",
		"F",
		"N",
		"J",
		"K",
		"L",
		"H",
		"D",
		"W",
		"E",
		"M",
		"B",
		"T",
	}
end

return M
