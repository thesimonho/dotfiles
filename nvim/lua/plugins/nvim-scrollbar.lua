return {
  "petertriho/nvim-scrollbar",
  event = "LazyFile",
  opts = {
    show_in_active_only = true,
    hide_if_all_visible = false,
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
    handle = {
      blend = 50,
      color = "#54546D",
      hide_if_all_visible = false,
    },
    handlers = {
      cursor = true,
      diagnostic = true,
      gitsigns = true,
      handle = true,
    },
  },
}
