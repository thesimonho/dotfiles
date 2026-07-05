-- Shared markdownlint rule config lives in `.markdownlint.yaml` next to this
-- file. That location isn't on markdownlint-cli2's upward config search path, so
-- point both the formatter and the linter at it explicitly.
local markdownlintConfigPath = vim.fn.stdpath("config") .. "/lua/plugins/languages/.markdownlint.yaml"

M = {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- lsp
        "mdx-analyzer",
      },
    },
  },
  { -- formatter: markdownlint-cli2 fixes in place, so pass the shared config
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        ["markdownlint-cli2"] = {
          prepend_args = { "--config", markdownlintConfigPath },
        },
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
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    keys = {
      { "<leader>cp", ft = "markdown", vim.NIL },
      { "<localleader>m", ft = "markdown", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview" },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
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

-- The extra lints with markdownlint-cli2; point it
-- at the same shared config so the linter and formatter agree on rules.
local markdownlintCli2 = require("lint").linters["markdownlint-cli2"]
markdownlintCli2.args = {
  "--config",
  markdownlintConfigPath,
  "-",
}

return M
