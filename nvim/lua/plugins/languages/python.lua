local os_utils = require("utils.os")
if not os_utils.has_executable("python") then
  return {}
end

-- Share personal rule overrides with Ruff LSP and both Conform commands.
-- Other settings still come from each project's Ruff configuration.
local ruff = {
  ["line-length"] = 88,
  lint = {
    select = { "E", "F", "N", "I", "UP", "ANN", "S", "B", "A", "PT", "Q", "SIM", "PTH", "PD", "NPY", "PERF", "RUF" },
    ignore = {
      "D100",
      "D101",
      "D102",
      "D103",
      "D104",
      "D105",
      "D106",
      "D107",
      "D401",
      "D407",
      "D417",
      "E722",
      "F821",
      "F401",
      "S101",
    },
  },
}
local ruff_args = {
  "--config",
  "line-length = " .. ruff["line-length"],
  "--config",
  "lint.select = " .. vim.json.encode(ruff.lint.select),
  "--config",
  "lint.ignore = " .. vim.json.encode(ruff.lint.ignore),
}

local M = {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff = {
          init_options = {
            settings = {
              configuration = ruff,
              configurationPreference = "editorFirst",
            },
          },
        },
        pyright = {
          settings = {
            pyright = {
              disableOrganizeImports = true, -- Using Ruff
            },
            python = {
              analysis = {
                typeCheckingMode = "strict",
                diagnosticMode = "workspace",
                autoImportCompletions = true,
                diagnosticSeverityOverrides = {
                  reportMissingTypeStubs = "warning",
                  reportUnknownMemberType = "warning",
                  reportUnknownArgumentType = "warning",
                  reportUnknownVariableType = "warning",
                },
                inlayHints = {
                  variableTypes = true,
                  functionReturnTypes = true,
                  callArgumentNames = true,
                },
              },
            },
          },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "python",
      },
    },
  },
  { -- formatters
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        ruff_fix = { append_args = ruff_args },
        ruff_format = { append_args = ruff_args },
      },
      formatters_by_ft = {
        python = { "ruff_fix", "ruff_format" },
      },
    },
  },
}

return M
