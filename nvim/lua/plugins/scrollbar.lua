return {
  {
    "dstein64/nvim-scrollview",
    dependencies = { "lewis6991/gitsigns.nvim" },
    event = "LazyFile",
    init = function()
      vim.g.scrollview_keywords_bug_spec = {
        patterns = { "BUG" },
        highlight = "ScrollViewKeywordsFix",
        priority = 25,
        symbol = "",
      }
    end,
    config = function(_, opts)
      require("scrollview").setup(opts)
      require("scrollview.contrib.gitsigns").setup({
        add_symbol = "▏",
        add_priority = 5,
        change_symbol = "▏",
        change_priority = 5,
        delete_symbol = "▏",
        delete_priority = 5,
      })
    end,
    opts = {
      excluded_filetypes = { "bigfile", "which-key", "snacks_input", "snacks_picker_input", "trouble" },
      visibility = "always",
      current_only = true,
      floating_windows = true,
      hide_on_cursor_intersect = true,
      signs_on_startup = {
        "conflicts",
        "cursor",
        "diagnostics",
        "marks",
        "search",
      },
      signs_max_per_row = 1,
      signs_scrollbar_overlap = "over",
      cursor_priority = 100,
      diagnostics_error_symbol = "",
      diagnostics_warn_symbol = "",
      diagnostics_info_symbol = "",
      diagnostics_hint_symbol = "",
      diagnostics_severities = {
        vim.diagnostic.severity.ERROR,
        vim.diagnostic.severity.WARN,
      },
    },
  },
}
