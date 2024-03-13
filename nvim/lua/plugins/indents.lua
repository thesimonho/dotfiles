return {
  "shellRaining/hlchunk.nvim",
  event = "LazyFile",
  opts = {
    chunk = {
      enable = true,
      notify = true,
      use_treesitter = true,
      chars = {
        horizontal_line = "─",
        vertical_line = "│",
        left_top = "╭",
        left_bottom = "╰",
        right_arrow = ">",
      },
      style = {
        { fg = "#a292a3" },
        { fg = "#c4746e" }, -- this fg is used to highlight wrong chunk
      },
      textobject = "",
      max_file_size = 1024 * 1024,
      error_sign = true,
    },
    indent = {
      enable = true,
      use_treesitter = true,
      chars = {
        "│",
      },
      style = {
        { fg = "#2A2A37" },
      },
    },
    line_num = {
      enable = false,
    },
    blank = {
      enable = false,
    },
  },
}
