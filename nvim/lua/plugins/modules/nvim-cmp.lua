local M = {
	"hrsh7th/nvim-cmp",
	cond = vim.g.vscode == nil,
	enabled = true,
	dependencies = {
		"onsails/lspkind.nvim",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-nvim-lua",
	},
	event = { "InsertEnter" },
}

local has_words_before = function()
	if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
		return false
	end
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
end

function M.config()
	local cmp = require("cmp")
	local lspkind = require("lspkind")

	cmp.setup({
		preselect = cmp.PreselectMode.None,
		completion = {
			completeopt = "menu,menuone,noinsert,noselect",
		},
		snippet = {
			expand = function(args)
				require("luasnip").lsp_expand(args.body)
			end,
		},
		window = {
			completion = cmp.config.window.bordered(),
			documentation = cmp.config.window.bordered(),
		},
		formatting = {
			format = lspkind.cmp_format({
				mode = "symbol_text",
				max_width = 50,
			}),
		},
		mapping = {
			["<CR>"] = cmp.mapping.confirm({ select = true }),
			["<C-Space>"] = cmp.mapping.complete(),
			["<C-e>"] = cmp.mapping({
				i = cmp.mapping.abort(),
				c = cmp.mapping.close(),
			}),
			["<Tab>"] = vim.schedule_wrap(function(fallback)
				if cmp.visible() and has_words_before() then
					cmp.select_next_item({ behavior = cmp.SelectBehavior })
				elseif has_words_before() then
					cmp.complete()
				else
					fallback()
				end
			end),
			["<S-Tab>"] = vim.schedule_wrap(function(fallback)
				if cmp.visible() and has_words_before() then
					cmp.select_prev_item({ behavior = cmp.SelectBehavior })
				else
					fallback()
				end
			end),
		},
		sources = cmp.config.sources({
			{
				name = "luasnip",
				priority = 700,
				keyword_length = 2,
				max_item_count = 5,
				option = { show_autosnippets = false },
			},
			{ name = "jupynium", priority = 600, max_item_count = 5 }, -- consider higher priority than LSP
			{ name = "nvim_lsp", priority = 500, keyword_length = 1, max_item_count = 5 },
			{ name = "buffer", keyword_length = 3, max_item_count = 5 },
			{ name = "path", max_item_count = 5 },
			{ name = "crates" },
		}),
	})
end

return M
