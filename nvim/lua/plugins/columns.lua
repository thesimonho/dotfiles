return {
  {
    "mluders/comfy-line-numbers.nvim",
    enabled = false,
    event = "BufRead",
    opts = {
      enable_in_terminal = false,
    },
  },
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
}
