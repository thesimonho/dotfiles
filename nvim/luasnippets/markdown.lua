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
		{ trig = "tab", dscr = "Create table", snippetType = "snippet", regTrig = false },
		fmta(
			[[
        |     <>       |     <>        |      <>        |
        |   :----:   |   :----:    |    :----:    |
        | <>           | <>            | <>             |
        <>
        ]],
			{ i(1), i(2), i(3), i(4), i(5), i(6), i(0) }
		)
	),
	s(
		{ trig = "task", dscr = "Create task item", snippetType = "snippet", regTrig = false },
		fmta(
			[=[
            - [<>] <>
        ]=],
			{ i(1, "x"), i(2) }
		)
	),
	s(
		{ trig = "img", dscr = "Create image", snippetType = "snippet", regTrig = false },
		fmta(
			[=[
            ![alt](<>)
        ]=],
			{ i(1, "image.png") }
		)
	),
	s(
		{ trig = "link", dscr = "Create link", snippetType = "snippet", regTrig = false },
		fmta(
			[=[
            [<>](<>)
        ]=],
			{ i(1, "text"), i(2, "url") }
		)
	),
}
