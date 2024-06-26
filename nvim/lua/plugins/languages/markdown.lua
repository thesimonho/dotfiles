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
    "lukas-reineke/headlines.nvim",
    ft = { "markdown", "quarto" },
    opts = {
      markdown = {
        headline_highlights = { "Headline1", "Headline2", "Headline3" },
        fat_headlines = true,
        fat_headline_upper_string = "▄",
        fat_headline_lower_string = "▀",
      },
    },
  },
}
