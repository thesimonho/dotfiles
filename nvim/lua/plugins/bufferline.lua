return {
  "akinsho/bufferline.nvim",
  keys = {
    { "<leader>bl", vim.NIL },
    { "<leader>br", vim.NIL },
    { "<leader>bo", vim.NIL },
    { "<leader>bD", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete other buffers" },
    { "<leader><space>", "<Cmd>BufferLinePick<CR>", desc = "Pick buffer" },
  },
  opts = {
    options = {
      -- stylua: ignore
      close_command = function(n) require("mini.bufremove").delete(n, false) end,
      -- stylua: ignore
      right_mouse_command = function(n) require("mini.bufremove").delete(n, false) end,
      mode = "buffers", -- set to "tabs" to only show tabpages instead
      numbers = "none",
      indicator = {
        icon = "▎", -- this should be omitted if indicator style is not 'icon'
        style = "icon",
      },
      hover = {
        enabled = true,
        delay = 200,
        reveal = { "close" },
      },
      buffer_close_icon = "",
      modified_icon = "●",
      close_icon = "",
      left_trunc_marker = "",
      right_trunc_marker = "",
      truncate_names = true, -- whether or not tab names should be truncated
      color_icons = true, -- whether or not to add the filetype icon highlights
      show_buffer_icons = true, -- disable filetype icons for buffers
      show_buffer_close_icons = true,
      show_close_icon = true,
      show_tab_indicators = true,
      show_duplicate_prefix = true, -- whether to show duplicate buffer prefix
      persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
      separator_style = "thick",
      enforce_regular_tabs = false,
      always_show_bufferline = true,
      sort_by = "extension",
      offsets = {
        {
          filetype = "aerial",
          text = "Outline",
          text_align = "center",
          separator = false,
        },
        {
          filetype = "OverseerList",
          text = "Tasks",
          text_align = "center",
          separator = false,
        },
        {
          filetype = "neo-tree",
          text = "Neotree",
          -- highlight = "Directory",
          text_align = "left",
          separator = true,
        },
      },
      diagnostics = false,
      style_preset = {
        require("bufferline").style_preset.no_italic,
        require("bufferline").style_preset.no_bold,
      },
    },
  },
}
