return {
  "petertriho/nvim-scrollbar",
  enabled = false,
  event = "LazyFile",
  opts = {
    show_in_active_only = true,
    hide_if_all_visible = false,
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
      "Outline",
      "OverseerList",
      "OverseerForm",
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

-- OR:
-- https://github.com/gorbit99/codewindow.nvim
-- https://github.com/wfxr/minimap.vim
