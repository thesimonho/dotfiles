M = {
  {
    "mason-org/mason.nvim",
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
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "markdown",
        "markdown_inline",
      },
    },
  },
  { -- formatters
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        markdown = { "prettierd", "markdownlint" },
        ["markdown.mdx"] = { "prettierd", "markdownlint" },
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
    ft = { "markdown" },
    opts = {
      file_types = { "markdown" },
      render_modes = { "n", "c", "v", "t" },
      preset = "lazy",
      nested = false,
      completions = {
        blink = { enabled = true },
      },
      heading = {
        position = "inline",
        sign = true,
        border = false,
        width = "full",
        icons = false,
      },
      code = {
        sign = true,
        width = "block",
        conceal_delimiters = false,
        language = false,
        min_width = 60,
        left_pad = 0,
        language_pad = 0,
      },
      pipe_table = {
        enabled = false,
        preset = "round",
        alignment_indicator = "┅",
      },
      sign = {
        enabled = true,
        highlight = "RenderMarkdownSign",
      },
      win_options = {
        conceallevel = {
          default = vim.o.conceallevel,
          rendered = vim.o.conceallevel,
        },
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
