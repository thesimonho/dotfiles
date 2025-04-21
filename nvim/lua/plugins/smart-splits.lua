return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  keys = {
    { "<C-h>", "<cmd>lua require('smart-splits').move_cursor_left()<cr>", desc = "Move cursor left" },
    { "<C-j>", "<cmd>lua require('smart-splits').move_cursor_down()<cr>", desc = "Move cursor down" },
    { "<C-k>", "<cmd>lua require('smart-splits').move_cursor_up()<cr>", desc = "Move cursor up" },
    { "<C-l>", "<cmd>lua require('smart-splits').move_cursor_right()<cr>", desc = "Move cursor right" },
    { "<M-Left>", "<cmd>lua require('smart-splits').resize_left()<cr>", desc = "Resize left" },
    { "<M-Right>", "<cmd>lua require('smart-splits').resize_right()<cr>", desc = "Resize right" },
    { "<M-Up>", "<cmd>lua require('smart-splits').resize_up()<cr>", desc = "Resize up" },
    { "<M-Down>", "<cmd>lua require('smart-splits').resize_down()<cr>", desc = "Resize down" },
    { "<leader>wr", "<cmd>lua require('smart-splits').start_resize_mode()<cr>", desc = "Start resize mode" },
  },
  opts = {
    at_edge = "split",
    multiplexer_integration = false,
    disable_multiplexer_nav_when_zoomed = true,
    resize_mode = {
      silent = true,
      hooks = {
        on_enter = function()
          vim.notify("Entering resize mode")
        end,
        on_leave = function()
          vim.notify("Exiting resize mode ")
        end,
      },
    },
  },
}
