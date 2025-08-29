return {
  "monaqa/dial.nvim",
  opts = function(_, opts)
    -- LazyVim adds augend.integer.alias.decimal_int as default, which creates a lot of isses when working with CSS/tailwind classes that takes the format of pa-1, pa-2, causing dial to treat the number as negative
    -- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/editor/dial.lua
    table.remove(opts.groups.default, 2)
  end,
}
