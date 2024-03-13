M = {
  {
    "williamboman/mason.nvim",
    keys = {
      { "<leader>cm", vim.NIL },
    },
    opts = {
      ensure_installed = {
        -- lsp
        "graphql-language-service-cli",
        "gopls",
        "marksman",
        "lua-language-server",
        "pyright",
        "ruff-lsp",
        "terraform-ls",
        "typescript-language-server",
        "vim-language-server",
        "yaml-language-server",
        "vue-language-server",

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
      },
    },
  },
  { -- formatters
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        css = { { "prettierd", "prettier" } },
        html = { { "prettierd", "prettier" } },
        go = { "goimports", "golines", "gofumpt" },
        graphql = { { "prettierd", "prettier" } },
        javascript = { { "prettierd", "prettier" } },
        json = { { "prettierd", "prettier" } },
        lua = { "stylua" },
        markdown = { { "prettierd", "prettier" } },
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
        javascript = { "eslint_d" },
        go = { "golangcilint" },
        markdown = { "markdownlint" },
        python = { "ruff" },
      },
    },
  },
}

local ruff = require("lint").linters.ruff
table.insert(ruff.args, 1, "--select=E,F,N,D,I,UP,ANN,S,B,A,PT,Q,SIM,PTH,PD,NPY,PERF")
table.insert(ruff.args, 1, "--ignore=ANN101,D100,D101,D102,D103,D104,D105,D106,D107,D401,D417,E722,E999,F821,F401")
table.insert(ruff.args, 1, "--line-length=88")

return M
