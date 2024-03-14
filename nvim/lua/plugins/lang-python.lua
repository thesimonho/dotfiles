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
      { "<localleader>v", "<cmd>:VenvSelect<cr>", ft = "python", desc = "virtualenv" },
    },
  },
}
