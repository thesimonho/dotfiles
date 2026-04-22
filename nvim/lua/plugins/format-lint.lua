return {
  {
    "mason-org/mason.nvim",
    keys = {
      { "<leader>cm", vim.NIL },
    },
    opts = {
      ensure_installed = {
        -- lint
        "shellcheck",
        -- formatters
        "yamlfmt",
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
      },
      formatters_by_ft = {
        yaml = { "yamlfmt" },
      },
    },
  },
}
