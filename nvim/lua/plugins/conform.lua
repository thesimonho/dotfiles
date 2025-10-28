return {
  {
    "mason-org/mason.nvim",
    keys = {
      { "<leader>cm", vim.NIL },
    },
    opts = {
      ensure_installed = {
        -- formatters
        "prettierd",
        "prettier",
        "yamlfmt",
        "kdlfmt",
      },
    },
  },
  { -- formatters
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        injected = {
          options = {
            ignore_errors = false,
            lang_to_ext = {
              bash = "sh",
              javascript = "js",
              julia = "jl",
              latex = "tex",
              markdown = "md",
              python = "py",
              r = "r",
              typescript = "ts",
            },
          },
        },
        prettierd = {
          options = {
            ext_parsers = {
              qmd = "markdown",
            },
          },
        },
      },
      formatters_by_ft = {
        graphql = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "yamlfmt" },
        kdl = { "kdlfmt" },
      },
    },
  },
}
