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
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "Avante" },
    opts = {
      file_types = { "markdown", "Avante" },
      completions = {
        blink = { enabled = true },
      },
      heading = {
        position = "inline",
        sign = true,
        signs = { "󰫎 " },
        border = true,
        width = "full",
        icons = { " 󰲡 ", " 󰲣 ", " 󰲥 ", " 󰲧 ", " 󰲩 ", " 󰲫 " },
      },
      code = {
        sign = true,
        style = "full",
        width = "block",
        min_width = 60,
        left_pad = 2,
        language_pad = 2,
      },
      pipe_table = {
        preset = "round",
        alignment_indicator = "┅",
      },
      sign = {
        enabled = true,
        highlight = "RenderMarkdownSign",
      },
    },
  },
}
