local style = require("utils.style")

return {
  "folke/noice.nvim",
  opts = {
    presets = {
      bottom_search = true, -- use a classic bottom cmdline for search
      command_palette = true, -- position the cmdline and popupmenu together
      long_message_to_split = true, -- long messages will be sent to a split
      lsp_doc_border = true, -- add a border to hover docs and signature help
    },
    lsp = {
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
    },
    views = {
      hover = {
        border = {
          style = style.border_chars_outer_thin,
        },
      },
      mini = {
        win_options = {
          winblend = 15,
        },
      },
      confirm = {
        position = "50%",
      },
    },
  },
}
