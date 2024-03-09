return {
  "petertriho/nvim-scrollbar",
  event = "LazyFile",
  opts = {
    show_in_active_only = true,
    excluded_filetypes = {
      "cmp_docs",
      "cmp_menu",
      "noice",
      "prompt",
      "TelescopePrompt",
      "DressingInput",
      "neo-tree",
      "mason",
      "lazy",
      "Glance",
      "Outline",
    },
    handlers = {
      cursor = true,
      diagnostic = true,
      gitsigns = true,
      handle = true,
    },
  },
}
