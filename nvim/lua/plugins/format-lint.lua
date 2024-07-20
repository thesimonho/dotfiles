M = {
  {
    "williamboman/mason.nvim",
    keys = {
      { "<leader>cm", vim.NIL },
    },
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        -- linters
        "eslint_d",
        "markdownlint",
        "golangci-lint",
        "ruff",

        -- formatters
        "prettierd",
        "stylua",
        "goimports",
        "golines",
        "gofumpt",
        "yamlfmt",
      })
    end,
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
        prettier = {
          options = {
            ext_parsers = {
              qmd = "markdown",
            },
          },
        },
      },
      formatters_by_ft = {
        css = { { "prettierd", "prettier" } },
        html = { { "prettierd", "prettier" } },
        go = { "goimports", "golines", "gofumpt" },
        graphql = { { "prettierd", "prettier" } },
        javascript = { { "prettierd", "prettier" } },
        json = { { "prettierd", "prettier" } },
        lua = { "stylua" },
        markdown = { { "prettierd", "prettier" }, "markdownlint", "markdown-toc" },
        python = { "ruff_fix", "ruff_format" },
        terraform = { "terraform_fmt" },
        typescript = { { "prettierd", "prettier" } },
        vue = { { "prettierd", "prettier" } },
        yaml = { "yamlfmt" },
      },
    },
  },
  { -- linters
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        go = { "golangcilint" },
        javascript = { "eslint_d" },
        markdown = { "markdownlint" },
        python = { "ruff" },
        typescript = { "eslint_d" },
        vue = { "eslint_d" },
      },
    },
  },
}

local ruff = require("lint").linters.ruff
table.insert(ruff.args, 1, "--line-length=88")
table.insert(ruff.args, 1, "--select=E,F,N,I,UP,ANN,S,B,A,PT,Q,SIM,PTH,PD,NPY,PERF,RUF")
table.insert(
  ruff.args,
  1,
  "--ignore=ANN101,D100,D101,D102,D103,D104,D105,D106,D107,D401,D407,D417,E722,E999,F821,F401,S101"
)

local markdownlint = require("lint").linters.markdownlint
markdownlint.args = {
  "--disable",
  "html",
  "line_length",
  "spelling",
  "--", -- Required
}

return M
