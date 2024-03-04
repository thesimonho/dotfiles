local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local l = require("luasnip.extras").lambda
local rep = require("luasnip.extras").rep
local p = require("luasnip.extras").partial
local m = require("luasnip.extras").match
local n = require("luasnip.extras").nonempty
local dl = require("luasnip.extras").dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local types = require("luasnip.util.types")
local conds = require("luasnip.extras.conditions")
local conds_expand = require("luasnip.extras.conditions.expand")
local utils = require("utils")

return {
	s(
		{ trig = "impp", dscr = "Import plot modules", snippetType = "snippet", regTrig = false },
		fmta(
			[[
            import seaborn as sns
            import matplotlib.pyplot as plt
            import matplotx
            import pygwalker as pyg
            plt.style.use(matplotx.styles.ayu["light"])
        ]],
			{}
		)
	),
	s(
		{ trig = "sns1", dscr = "Seaborn plot with 1 variable", snippetType = "snippet", regTrig = false },
		fmta(
			[[
            p = sns.<>plot(data=<>, x="<>")
            p.set(title="<>plot of <>", xlabel="<>")
        ]],
			{ c(1, { t("hist"), t("count"), t("dist") }), i(2, "df"), i(3), rep(1), rep(3), rep(3) }
		)
	),
	s(
		{ trig = "sns2", dscr = "Seaborn plot with 2 variables", snippetType = "snippet", regTrig = false },
		fmta(
			[[
            p = sns.<>plot(data=<>, x="<>", y="<>")
            p.set(title="<>plot of <> and <>", xlabel="<>")
            matplotx.ylabel_top("<>")
        ]],
			{
				c(1, { t("bar"), t("box"), t("line"), t("scatter"), t("lm") }),
				i(2, "df"),
				i(3),
				i(4),
				rep(1),
				rep(3),
				rep(4),
				rep(3),
				rep(4),
			}
		)
	),
	s(
		{ trig = "sns2hue", dscr = "Seaborn 2 variable plot by hue", snippetType = "snippet", regTrig = false },
		fmta(
			[[
            p = sns.<>plot(data=<>, x="<>", y="<>", hue="<>")
            p.set(title="<>plot of <> and <>\ngrouped by <>", xlabel="<>")
            matplotx.ylabel_top("<>")
        ]],
			{
				c(1, { t("bar"), t("line"), t("lm"), t("scatter") }),
				i(2, "df"),
				i(3),
				i(4),
				i(5),
				rep(1),
				rep(3),
				rep(4),
				rep(5),
				rep(3),
				rep(4),
			}
		)
	),
	s(
		{ trig = "fig", dscr = "matplotlib subplot setup with defined ax", snippetType = "snippet", regTrig = false },
		fmta(
			[[
            fig, ax = plt.subplots(<>, <>)
            <>
            fig.tightlayout()
            plt.show()
        ]],
			{ i(1, "1"), i(2, "1"), i(0) }
		)
	),
}
