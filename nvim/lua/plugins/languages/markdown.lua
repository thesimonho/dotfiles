M = {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        -- linters
        "markdownlint",
        -- formatters
        "prettierd",
        -- lsp
        "mdx-analyzer",
      },
    },
  },
  { -- formatters
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        markdown = { "prettierd", "markdownlint", "markdown-toc" },
        ["markdown.mdx"] = { "prettierd", "markdownlint", "markdown-toc" },
      },
    },
  },
  { -- linters
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        markdown = { "markdownlint" },
      },
    },
  },
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
    ft = { "markdown", "Avante", "copilot-chat" },
    opts = {
      file_types = { "markdown", "Avante", "copilot-chat" },
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

local markdownlint = require("lint").linters.markdownlint
markdownlint.args = {
  "--disable",
  "html",
  "line_length",
  "spelling",
  "--", -- Required
}

return M
