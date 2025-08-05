local os_utils = require("utils.os")
if not os_utils.has_executable("python") then
  return {}
end

M = {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            pyright = {
              disableOrganizeImports = true, -- Using Ruff
            },
          },
        },
      },
    },
  },
  { -- formatters
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_fix", "ruff_format" },
      },
    },
  },
  { -- linters
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        python = { "ruff" },
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

-- Add filetype for plenary.nvim
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyLoad",
  desc = "Add plenary filetypes",
  callback = function(args)
    if args.data ~= "plenary.nvim" then
      return
    end

    require("plenary").filetype.add_table({
      extension = {
        py = "python",
      },
    })
  end,
})

return M
