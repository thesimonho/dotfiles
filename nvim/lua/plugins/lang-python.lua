return {
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
        ruff_lsp = {
          init_options = {
            settings = {
              lint = {
                args = {
                  "--select=E,F,N,D,I,UP,ANN,S,B,A,PT,Q,SIM,PTH,PD,NPY,PERF",
                  "--ignore=ANN101,D100,D101,D102,D103,D104,D105,D106,D107,D401,D417,E999,F821,F401",
                  "--line-length=88",
                },
              },
              format = {
                args = {
                  "--line-length=88",
                },
              },
            },
          },
        },
      },
    },
  },
  {
    "linux-cultist/venv-selector.nvim",
    cmd = "VenvSelect",
    ft = "python",
    keys = {
      { "<leader>cv", vim.NIL },
      { "<leader>zv", "<cmd>:VenvSelect<cr>", desc = "Python VirtualEnv" },
    },
  },
}
