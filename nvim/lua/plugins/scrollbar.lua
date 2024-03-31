return {
  { -- checkout satellite.nvim when nvim 0.10
    "dstein64/nvim-scrollview",
    enabled = true,
    dependencies = { "lewis6991/gitsigns.nvim" },
    event = "LazyFile",
    config = function(_, opts)
      require("scrollview").setup(opts)
      require("scrollview.contrib.gitsigns").setup({ hide_full_add = false })
      vim.api.nvim_create_autocmd("FocusGained", {
        pattern = "*",
        callback = function()
          vim.cmd("ScrollViewRefresh")
        end,
        desc = "Refresh scrollbar on focus",
      })
    end,
    opts = {
      mode = "simple",
      always_show = true,
      current_only = true,
      signs_max_per_row = 2,
      hover = false,
      zindex = 50,
      diagnostics_severities = { vim.diagnostic.severity.WARN },
      excluded_filetypes = {
        "cmp_docs",
        "cmp_menu",
        "noice",
        "prompt",
        "notify",
        "TelescopePrompt",
        "DressingInput",
        "toggleterm",
        "neo-tree",
        "mason",
        "lazy",
        "Glance",
        "OverseerList",
        "OverseerForm",
      },
      signs_on_startup = { "diagnostics", "search", "folds", "cursor", "quickfix", "conflicts", "loclist", "marks" },
    },
  },
}
