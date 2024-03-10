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
