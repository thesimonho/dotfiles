return {
  "b0o/incline.nvim",
  event = "LazyFile",
  opts = {
    hide = {
      cursorline = false,
      focused_win = false,
      only_win = false,
    },
    highlight = {
      groups = {
        InclineNormal = {
          default = true,
          group = "InclineNormal",
        },
        InclineNormalNC = {
          default = true,
          group = "InclineNormalNC",
        },
      },
    },
    render = function(props)
      local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
      if filename == "" then
        filename = "[No Name]"
      end
      local ft_icon, ft_color = require("nvim-web-devicons").get_icon_color(filename)
      return {
        ft_icon
            and { " ", ft_icon, " ", guibg = ft_color, guifg = require("incline.helpers").contrast_color(ft_color) }
          or " ",
        " ",
        { filename },
      }
    end,
    ignore = {
      buftypes = "special",
      wintypes = "special",
      filetypes = {},
    },
    window = {
      margin = {
        horizontal = 2,
        vertical = 1,
      },
      padding = { left = 0, right = 1 },
      padding_char = " ",
      placement = {
        horizontal = "right",
        vertical = "top",
      },
      zindex = 50,
    },
  },
}
