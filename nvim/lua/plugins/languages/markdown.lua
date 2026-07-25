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
  {
    "jakewvincent/mkdnflow.nvim",
    depedencies = {
      {
        "saghen/blink.cmp",
        opts = {
          sources = {
            default = { "lsp", "mkdnflow" },
            providers = {
              mkdnflow = {
                name = "Mkdnflow",
                module = "mkdnflow.completion.blink",
              },
            },
          },
        },
      },
    },
    ft = { "markdown", "rmd" },
    opts = {
      modules = {
        conceal = true,
        yaml = true,
        completion = true,
      },
      create_dirs = false,
      silent = true,
      path_resolution = {
        sync_cwd = true,
        update_on_navigate = true,
      },
      foldtext = {
        object_count = true,
        object_count_icon_set = "nerdfont",
        line_count = true,
        line_percentage = false,
        word_count = false,
        fill_chars = {
          left_edge = "⣿",
          right_edge = "⣿",
          item_separator = " · ",
          section_separator = "  //  ",
          left_inside = " ┃",
          right_inside = "┃ ",
          middle = "⣿",
        },
      },
      links = {
        compact = false,
        conceal = true,
        auto_create = true,
      },
      to_do = {
        highlight = true,
        statuses = {
          not_started = {
            marker = " ",
            highlight = {
              marker = { link = "Conceal" },
              content = { link = "Conceal" },
            },
            sort = { section = 2, position = "top" },
          },
          in_progress = {
            marker = "-",
            highlight = {
              marker = { link = "WarningMsg" },
              content = { bold = true },
            },
            sort = { section = 1, position = "bottom" },
          },
          complete = {
            marker = { "X", "x" },
            highlight = {
              marker = { link = "String" },
              content = { link = "Conceal" },
            },
            sort = { section = 3, position = "top" },
          },
        },
        status_order = { "not_started", "in_progress", "complete" },
        sort = {
          on_status_change = true,
          recursive = true,
        },
      },
      tables = {
        type = "pipe",
        trim_whitespace = true,
        format_on_move = true,
        style = {
          cell_padding = 1,
          separator_padding = 1,
          outer_pipes = true,
          apply_alignment = true,
        },
      },
      mappings = {
        MkdnEnter = { { "n", "v" }, "<CR>" },
        MkdnGoBack = { "n", "<BS>" },
        MkdnGoForward = { "n", "<Del>" },
        MkdnMoveSource = { "n", "<F2>" },
        MkdnNextLink = false,
        MkdnPrevLink = false,
        MkdnFollowLink = false,
        MkdnDestroyLink = { "n", "<M-CR>" },
        MkdnTagSpan = { "v", "<M-CR>" },
        MkdnYankAnchorLink = { "n", "yaa" },
        MkdnYankFileAnchorLink = { "n", "yfa" },
        MkdnNextHeading = { "n", "]]" },
        MkdnPrevHeading = { "n", "[[" },
        MkdnNextHeadingSame = { "n", "][" },
        MkdnPrevHeadingSame = { "n", "[]" },
        MkdnIncreaseHeading = { { "n", "v" }, "+" },
        MkdnDecreaseHeading = { { "n", "v" }, "-" },
        MkdnIncreaseHeadingOp = { { "n", "v" }, "g+" },
        MkdnDecreaseHeadingOp = { { "n", "v" }, "g-" },
        MkdnToggleToDo = { { "n", "v" }, "<Tab>" },
        MkdnNewListItemBelowInsert = { "n", "o" },
        MkdnNewListItemAboveInsert = { "n", "O" },
        MkdnUpdateNumbering = { "n", "<leader>nn" },
        MkdnTableNextCell = { "i", "<Tab>" },
        MkdnTablePrevCell = { "i", "<S-Tab>" },
        MkdnTableNextRow = false,
        MkdnTablePrevRow = { "i", "<M-CR>" },
        MkdnTableNewRowBelow = { "n", "<leader>ir" },
        MkdnTableNewRowAbove = { "n", "<leader>iR" },
        MkdnTableNewColAfter = { "n", "<leader>ic" },
        MkdnTableNewColBefore = { "n", "<leader>iC" },
        MkdnTableDeleteRow = { "n", "<leader>dr" },
        MkdnTableDeleteCol = { "n", "<leader>dc" },
        MkdnFoldSection = { "n", "<leader>f" },
        MkdnUnfoldSection = { "n", "<leader>F" },
        MkdnTab = false,
        MkdnSTab = false,
        MkdnIndentListItem = { "i", "<C-t>" },
        MkdnDedentListItem = { "i", "<C-d>" },
        MkdnCreateLink = false,
        MkdnCreateLinkFromClipboard = { { "n", "v" }, "<leader>p" },
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
