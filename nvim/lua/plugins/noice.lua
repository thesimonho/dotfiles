return {
  "folke/noice.nvim",
  opts = {
    lsp = {
      progress = {
        override = {
          -- override the default lsp markdown formatter with Noice
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          -- override the lsp markdown formatter with Noice
          ["vim.lsp.util.stylize_markdown"] = true,
          -- override cmp documentation with Noice (needs the other options to work)
          ["cmp.entry.get_documentation"] = true,
        },
      },
    },
    views = {
      mini = {
        win_options = {
          winblend = 100,
        },
      },
    },
  },
}
