return {
  "hedyhli/outline.nvim",
  cmd = { "Outline", "OutlineOpen" },
  keys = {
    { "<leader>cs", "<cmd>Outline<cr>", desc = "Symbols Outline" },
  },
  opts = {
    outline_window = {
      width = 35,
      relative_width = true,
      show_numbers = false,
      show_relative_numbers = false,
      wrap = false,
      show_cursorline = true,
      hide_cursor = true,
      focus_on_open = true,
    },
    symbol_folding = {
      -- Depth past which nodes will be folded by default. Set to false to unfold all on open.
      autofold_depth = 1,
      -- When to auto unfold nodes
      auto_unfold = {
        -- Auto unfold currently hovered symbol
        hovered = true,
        -- Auto fold when the root level only has this many nodes.
        -- Set true for 1 node, false for 0.
        only = true,
      },
    },
    preview_window = {
      auto_preview = true,
    },
  },
}
