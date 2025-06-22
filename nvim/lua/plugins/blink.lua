return {
  "saghen/blink.cmp",
  dependencies = {
    "mikavilpas/blink-ripgrep.nvim",
    "Kaiser-Yang/blink-cmp-git",
  },
  opts = {
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
    sources = {
      default = {
        "ripgrep",
        "git",
      },
      providers = {
        ripgrep = {
          module = "blink-ripgrep",
          name = "ripgrep",
          opts = {
            prefix_min_len = 5,
            context_size = 3,
            search_casing = "--smart-case",
          },
        },
        git = {
          module = "blink-cmp-git",
          name = "git",
          enabled = function()
            return vim.tbl_contains({ "octo", "gitcommit", "markdown" }, vim.bo.filetype)
          end,
        },
      },
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
          preselect = true,
          auto_insert = false,
        },
      },
      ghost_text = {
        enabled = false,
      },
      menu = {
        enabled = true,
        min_width = 40,
        max_height = 15,
        winblend = 6,
        border = "rounded",
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
          border = "rounded",
          winblend = 6,
        },
      },
    },
  },
}
