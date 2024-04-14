return {
  "sindrets/diffview.nvim",
  event = "LazyFile",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview" },
    { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
  },
  opts = {
    view = {
      default = {
        -- Config for changed files, and staged files in diff views.
        layout = "diff2_horizontal",
        winbar_info = true,
      },
      merge_tool = {
        -- Config for conflicted files in diff views during a merge or rebase.
        layout = "diff3_mixed",
        disable_diagnostics = true,
        winbar_info = true,
      },
      file_history = {
        -- Config for changed files in file history views.
        layout = "diff2_horizontal",
        winbar_info = true,
      },
    },
  },
}
