return {
  "m4xshen/hardtime.nvim",
  event = "LazyFile",
  dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
  opts = {
    disable_mouse = false,
    allow_different_key = true,
    max_count = 4,
    disabled_keys = {
      ["<Up>"] = {},
      ["<Down>"] = {},
      ["<Left>"] = {},
      ["<Right>"] = {},
    },
    disabled_filetypes = {
      "TelescopePrompt",
      "alpha",
      "checkhealth",
      "dapui*",
      "Diffview*",
      "Dressing*",
      "help",
      "lazy",
      "mason",
      "neotest-summary",
      "neo-tree",
      "netrw",
      "noice",
      "notify",
      "prompt",
      "qf",
      "trouble",
    },
  },
}
