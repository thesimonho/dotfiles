return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  opts = {
    disable_filetype = { "TelescopePrompt", "spectre_panel" },
    ignored_next_char = [=[[%w%%%'%[%"%.%`%$]]=],
    enable_afterquote = true, -- add bracket pairs after quote
    enable_check_bracket_line = true, --- check bracket in same line
    enable_bracket_in_quote = true, --
    check_ts = true,
    map_cr = true,
    map_bs = true, -- map the <BS> key
    map_c_h = false, -- Map the <C-h> key to delete a pair
    map_c_w = false, -- map <c-w> to delete a pair if possible
  },
  init = function()
    local npairs = require("nvim-autopairs")
    local Rule = require("nvim-autopairs.rule")
    local cond = require("nvim-autopairs.conds")

    local function bracket_insert(a1, ins, a2, lang)
      npairs.add_rule(Rule(ins, ins, lang)
        :with_pair(function(opts)
          return a1 .. a2 == opts.line:sub(opts.col - #a1, opts.col + #a2 - 1)
        end)
        :with_move(cond.none())
        :with_cr(cond.none())
        :with_del(function(opts)
          local col = vim.api.nvim_win_get_cursor(0)[2]
          return a1 .. ins .. ins .. a2 == opts.line:sub(col - #a1 - #ins + 1, col + #ins + #a2)
        end))
    end

    local brackets = { { "(", ")" }, { "[", "]" }, { "{", "}" } }
    for _, bracket in pairs(brackets) do
      bracket_insert(bracket[1], " ", bracket[2]) -- insert space between brackets
    end
  end,
}
