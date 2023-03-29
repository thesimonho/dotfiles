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
local ts_utils = require("nvim-treesitter.ts_utils")
local ts_locals = require("nvim-treesitter.locals")
local utils = require("utils")

return {
	s(
		{ trig = "ifmain", dscr = "If name == main", snippetType = "autosnippet", regTrig = false },
		fmta(
			[[
            if __name__ == "__main__":
                <>
        ]],
			{ i(1, "pass") }
		)
	),
	s(
		{ trig = "frin", dscr = "For loop", snippetType = "autosnippet", regTrig = false },
		fmta(
			[[
            for <> in <>:
                <>
        ]],
			{
				f(function(args)
					s = args[1][1]
					return s:sub(1, 1):lower()
				end, { 1 }),
				i(1),
				i(0, "pass"),
			}
		)
	),
	s(
		{ trig = "fren", dscr = "For enumerate", snippetType = "autosnippet", regTrig = false },
		fmta(
			[[
            for i, <> in enumerate(<>):
                <>
        ]],
			{
				f(function(args)
					s = args[1][1]
					return s:sub(1, 1):lower()
				end, { 1 }),
				i(1),
				i(0, "pass"),
			}
		)
	),
	s(
		{ trig = "lc", dscr = "List comprehension", snippetType = "autosnippet", regTrig = false },
		fmta(
			[[
            [<> for <> in <> if <>]
        ]],
			{ i(1), i(2), i(3), i(4) }
		)
	),
	s(
		{ trig = "try", dscr = "Try/Except", snippetType = "snippet", regTrig = false },
		fmta(
			[[
            try:
                <>
            except <> as e:
                <>
        ]],
			{ i(1, "pass"), i(2, "Exception"), i(0, "print(e)") }
		)
	),
	s(
		{ trig = "def", dscr = "Define function or method", snippetType = "snippet", regTrig = false },
		fmt(
			[[
            def {}({}{}){}:
                {}
        ]],
			{
				i(1, "function"),
				f(function()
					local cnode = ts_utils.get_node_at_cursor(0)
					local scope = ts_locals.get_scope_tree(cnode)
					for _, node in ipairs(scope) do
						if node:type() == "class_definition" then
							return "self, "
						end
					end
					return ""
				end, {}),
				i(2, "args"),
				i(3, " -> None"),
				i(0, "pass"),
			}
		)
	),
}
