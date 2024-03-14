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

return {
  s(
    { trig = "snip", dscr = "Create lua snippet" },
    fmta(
      [=[
                s(
                    { trig = "<>", dscr = "<>", snippetType = "<>", regTrig = <> }, 
                    <>(
                    [[
                        <>
                    ]],
                    {<>})
                )
	        ]=],
      {
        i(1, "trig"),
        i(2, "dscr"),
        c(3, { t("snippet"), t("autosnippet") }),
        c(4, { t("false"), t("true") }),
        c(5, { t("fmta"), t("fmt") }),
        i(6, "snippet"),
        i(7, "node_list"),
      }
    )
  ),
  s(
    { trig = "fnm", dscr = "Create module function", snippetType = "autosnippet", regTrig = false },
    fmta(
      [[
                <>.<> = function(<>) 
                    <>
                end
	        ]],
      {
        i(1, "M"),
        i(2),
        i(3),
        i(4),
      }
    )
  ),
  s(
    { trig = "fnl", dscr = "Create function", snippetType = "autosnippet", regTrig = false },
    fmta(
      [[
                local <> = function(<>) 
                    <>
                end
	        ]],
      {
        i(1),
        i(2),
        i(3),
      }
    )
  ),
}
