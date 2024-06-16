return {
  "scheisa/relpointers.nvim",
  event = "LazyFile",
  opts = {
    amount = 2,
    distance = 5,

    hl_properties = { bg = "#2A2A37", underline = false },

    pointer_style = "line region",

    white_space_rendering = string.rep("\t\t\t\t\t", 50),

    virtual_pointer_position = -1,
    virtual_pointer_text = ">",

    enable_autocmd = true,
    autocmd_pattern = "*",
  },
}
