return {
  "saghen/blink.cmp",
  dependencies = {
    "mikavilpas/blink-ripgrep.nvim",
  },
  opts = {
    keymap = {
      ["<CR>"] = { "accept", "fallback" },
      ["<C-k>"] = { "show", "show_documentation", "hide_documentation" },
      ["<C-e>"] = { "hide", "fallback" },

      ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
      ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },

      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },

      ["<C-u>"] = { "scroll_documentation_up", "fallback" },
      ["<C-d>"] = { "scroll_documentation_down", "fallback" },
    },
    sources = {
      default = {
        "ripgrep",
      },
      providers = {
        ripgrep = {
          module = "blink-ripgrep",
          name = "ripgrep",
        },
      },
    },
    completion = {
      keyword = {
        range = "full",
      },
      trigger = {
        show_in_snippet = false,
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
