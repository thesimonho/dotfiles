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
		{ trig = "fn", dscr = "Create function", snippetType = "autosnippet", regTrig = false },
		fmta(
			[[
                fn <>(<>) ->> <> {
                    <>
                }
            ]],
			{ i(1), i(2), i(3, "()"), i(4, "()") }
		)
	),
	s(
		{ trig = "impl", dscr = "Create method", snippetType = "autosnippet", regTrig = false },
		fmta(
			[[
	           impl <> {
	               fn <>(<>) ->> <> {
	                   <>
	               }
	           }
           ]],
			{
				i(1),
				i(2),
				i(3, "&self"),
				i(4, "()"),
				i(5, "()"),
			}
		)
	),
	s(
		{ trig = "struct", dscr = "Create struct", snippetType = "autosnippet", regTrig = false },
		fmta(
			[[
                struct <> {
                    <>: <>,
                }
           ]],
			{
				i(1),
				i(2),
				i(3),
			}
		)
	),
	s(
		{
			trig = "(%s?=%s?)vec",
			dscr = "Create vector",
			snippetType = "autosnippet",
			regTrig = true,
			wordTrig = false,
		},
		fmta(
			[=[
            <>vec![<>];
        ]=],
			{
				utils.get_capture_group(1),
				i(0),
			}
		)
	),
	s(
		{
			trig = "(%s?=%s?)hm",
			dscr = "Create hashmap",
			snippetType = "autosnippet",
			regTrig = true,
			wordTrig = false,
		},
		fmta(
			[[
            <>HashMap::new();
            <>
        ]],
			{
				utils.get_capture_group(1),
				i(0),
			}
		)
	),
}
