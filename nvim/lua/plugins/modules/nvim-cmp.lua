local M = {
	"hrsh7th/nvim-cmp",
	enabled = true,
	dependencies = {
		"onsails/lspkind.nvim",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-nvim-lua",
		"hrsh7th/cmp-cmdline",
		"hrsh7th/cmp-emoji",
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
	local mapping = {
		["<CR>"] = cmp.mapping.confirm({ select = false }), -- don't autoselect first
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
	}

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
			completion = cmp.config.window.bordered({
				winhighlight = "Normal:Normal,FloatBorder:FloatBorder,Search:None",
				border = "single",
			}),
			documentation = cmp.config.window.bordered({
				winhighlight = "Normal:Normal,FloatBorder:FloatBorder,Search:None",
				border = "single",
			}),
		},
		formatting = {
			format = lspkind.cmp_format({
				mode = "symbol_text",
				max_width = 50,
			}),
		},
		matching = {
			disallow_fuzzy_matching = true,
			disallow_fullfuzzy_matching = true,
			disallow_partial_fuzzy_matching = true,
			disallow_partial_matching = true,
			disallow_prefix_unmatching = false,
		},
		mapping = mapping,
		sources = cmp.config.sources({
			{ name = "luasnip", priority = 700, keyword_length = 2, option = { show_autosnippets = true } },
			{ name = "otter" },
			{ name = "jupynium", priority = 600 }, -- consider higher priority than LSP
			{ name = "nvim_lsp", priority = 500, keyword_length = 1 },
			{ name = "buffer", keyword_length = 3 },
			{ name = "path" },
			{ name = "crates" },
			{ name = "emoji" },
		}),
	})

	-- FIXME: completion not showing up for this, or is not navigatable
	cmp.setup.cmdline({ "/", "?" }, {
		mapping = mapping,
		sources = {
			{ name = "buffer", keyword_length = 1 },
		},
	})

	-- cmp.setup.cmdline(":", {
	-- 	mapping = mapping,
	-- 	sources = cmp.config.sources({
	-- 		{ name = "path" },
	-- 	}, {
	-- 		{
	-- 			name = "cmdline",
	-- 			option = {
	-- 				ignore_cmds = { "Man", "!" },
	-- 			},
	-- 		},
	-- 	}),
	-- })

	-- cmp.setup.cmdline("@", {
	-- 	mapping = mapping,
	-- 	sources = cmp.config.sources({
	-- 		{ name = "path" },
	-- 		{ name = "cmdline" },
	-- 	}),
	-- })

	local cmp_autopairs = require("nvim-autopairs.completion.cmp")
	cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
end

return M
