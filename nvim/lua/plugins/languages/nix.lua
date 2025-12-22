return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "nix",
      },
    },
  },
  { -- formatters
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        nix = { "nixfmt" },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nixd = {
          settings = {
            nixd = {
              formatting = {
                command = { "nixfmt" },
              },
              nixpkgs = {
                expr = "import (builtins.getFlake(toString ./.)).inputs.nixpkgs { }",
              },
              options = {
                home = {
                  expr = '(builtins.getFlake(toString ./.)).homeConfigurations."home".options',
                },
                work = {
                  expr = '(builtins.getFlake(toString ./.)).homeConfigurations."work".options',
                },
              },
            },
          },
        },
      },
    },
  },
}
