return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      { "<leader>``", "<cmd>ToggleTermToggleAll<CR>", desc = "Toggle all" },
      { "<leader>`1", "<cmd>1ToggleTerm<CR>", desc = "Terminal 1" },
      { "<leader>`2", "<cmd>2ToggleTerm<CR>", desc = "Terminal 2" },
      { "<leader>`3", "<cmd>3ToggleTerm<CR>", desc = "Terminal 3" },
      { "<leader>`4", "<cmd>4ToggleTerm<CR>", desc = "Terminal 4" },
      { "<leader>`s", "<cmd>TermSelect<CR>", desc = "Select" },
    },
    opts = {
      autochdir = true,
      direction = "vertical",
      shell = "nu",
      start_in_insert = true,
      shade_terminals = false,
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
    },
  },
}
