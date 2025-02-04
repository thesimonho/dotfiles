return {
  {
    "Bekaboo/deadcolumn.nvim",
    event = "LazyFile",
    opts = {
      scope = "visible", -- line, buffer, visible
      modes = function(mode)
        return mode:find("^[nictRss\x13]") ~= nil
      end,
      blending = {
        threshold = 0.80,
        hlgroup = { "Normal", "bg" },
      },
      warning = {
        alpha = 0.1,
        offset = 0,
        hlgroup = { "lualine_a_insert", "bg" },
      },
    },
  },
  {
    "luukvbaal/statuscol.nvim",
    event = "LazyFile",
    config = function()
      local builtin = require("statuscol.builtin")
      require("statuscol").setup({
        relculright = true,
        segments = {
          {
            sign = {
              namespace = { "diagnostic/signs" },
              name = { ".*" },
              maxwidth = 2,
              colwidth = 1,
              auto = true,
              wrap = true,
            },
            click = "v:lua.ScSa",
          },
          { text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
          {
            sign = {
              namespace = { "gitsigns" },
              name = { ".*" },
              maxwidth = 1,
              colwidth = 1,
              auto = false,
            },
            click = "v:lua.ScSa",
          },
          { text = { builtin.foldfunc, " " }, auto = false, click = "v:lua.ScFa" },
        },
      })
    end,
  },
}
