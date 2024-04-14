return {
  "sindrets/diffview.nvim",
  event = "LazyFile",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview" },
    { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
  },
}
