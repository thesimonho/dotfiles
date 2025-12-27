local constants = require("config.constants")

local M = {
  {
    "saghen/blink.cmp",
    opts = {
      enabled = function()
        local exclude_filetypes = {
          "grug-far",
        }
        return not vim.tbl_contains(exclude_filetypes, vim.bo.filetype)
      end,
      keymap = {
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<CR>"] = { "accept", "fallback" },

        ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },

        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },

        ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
      },
      appearance = {
        nerd_font_variant = "normal",
      },
      completion = {
        keyword = {
          range = "full",
        },
        trigger = {
          show_on_insert = false,
          show_in_snippet = false,
          show_on_backspace = true,
          show_on_backspace_in_keyword = true,
        },
        list = {
          selection = {
            preselect = false,
            auto_insert = true,
          },
        },
        ghost_text = {
          enabled = false,
        },
        accept = {
          auto_brackets = {
            enabled = false,
          },
        },
        menu = {
          enabled = true,
          min_width = 40,
          max_height = 15,
          winblend = 0,
          border = "rounded",
          scrollbar = false,
          draw = {
            treesitter = { "lsp" },
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "source_name" },
            },
          },
        },
        documentation = {
          auto_show = true,
          treesitter_highlighting = true,
          window = {
            min_width = 10,
            max_width = 60,
            max_height = 20,
            scrollbar = false,
            border = constants.border_chars_dash,
            winblend = 0,
          },
        },
      },
    },
  },
}

return M
