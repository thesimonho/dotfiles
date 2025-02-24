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
    routes = {
      { -- @recording message
        filter = { event = "msg_showmode" },
        view = "notify",
      },
      { -- supermaven large file
        filter = {
          warning = true,
          find = "File is too large to send to server",
        },
        opts = { skip = true },
      },
      { -- supermaven free tier
        filter = {
          event = "msg_show",
          find = "Supermaven Free Tier is running.",
        },
        opts = { skip = true },
      },
    },
  },
}
