return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  keys = {
    { "<leader>E", "<cmd>Oil<cr>", desc = "Oil" },
  },
  opts = {
    delete_to_trash = true,
    keymaps = {
      ["<C-s>"] = "<cmd>lua require('oil').save()<cr>",
      ["<C-g>"] = "<cmd>bd<cr>",
    },
  },
}
