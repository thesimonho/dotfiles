return {
  "nvim-treesitter/nvim-treesitter-context",
  opts = {
    line_numbers = false,
    multiline_threshold = 10, -- Maximum number of lines to show for a single context
    trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
    mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
    separator = "-",
  },
}
