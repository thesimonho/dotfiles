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
        "vue-language-server", -- 1.8.27 is the latest version that works with nvim-lspconfig

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
      },
    },
  },
  { -- formatters
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { { "prettierd", "prettier" } },
        typescript = { { "prettierd", "prettier" } },
        markdown = { { "prettierd", "prettier" } },
        go = { "goimports", "golines", "gofumpt" },
        python = { "ruff_fix", "ruff_format" },
        ["_"] = { "trim_whitespace" },
      },
    },
  },
  { -- linters
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        javascript = { "eslint_d" },
        go = { "golangci-lint" },
        markdown = { "markdownlint" },
        python = { "ruff" },
      },
    },
  },
}

local ruff = require("lint").linters.ruff
table.insert(ruff.args, 1, "--select=E,F,N,D,I,UP,ANN,S,B,A,PT,Q,SIM,PTH,PD,NPY,PERF")
table.insert(ruff.args, 1, "--ignore=ANN101,D100,D101,D102,D103,D104,D105,D106,D107,D401,D417,E999,F821,F401")
table.insert(ruff.args, 1, "--line-length=88")

return M
