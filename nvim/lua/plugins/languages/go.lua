local os_utils = require("utils.os")
if not os_utils.has_executable("go") then
  return {}
end

return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "golangci-lint",
        "golines",
      },
    },
  },
  { -- formatters
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "goimports", "golines", "gofumpt" },
      },
    },
  },
  { -- linters
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        -- go = { "golangcilint" }, -- BUG: linter doesnt run, and takes LSP out when it tries
      },
    },
  },
}
