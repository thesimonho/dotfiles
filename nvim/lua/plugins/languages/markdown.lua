return {
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    keys = {
      { "<leader>cp", ft = "markdown", vim.NIL },
      { "<localleader>p", ft = "markdown", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview" },
    },
  },
  {
    "MeanderingProgrammer/markdown.nvim",
    opts = {
      heading = {
        width = "full",
      },
      code = {
        width = "full",
        left_pad = 2,
      },
    },
  },
}
