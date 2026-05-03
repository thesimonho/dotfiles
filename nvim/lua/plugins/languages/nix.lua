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
                expr = string.format(
                  'import (builtins.getFlake "git+file://%s/dotfiles?dir=nix").inputs.nixpkgs { }',
                  os.getenv("HOME")
                ),
              },
              options = {
                desktop = {
                  expr = string.format(
                    '(builtins.getFlake "git+file://%s/dotfiles?dir=nix").homeConfigurations.desktop.options',
                    os.getenv("HOME")
                  ),
                },
                ["work-macbook"] = {
                  expr = string.format(
                    '(builtins.getFlake "git+file://%s/dotfiles?dir=nix").homeConfigurations.work-macbook.options',
                    os.getenv("HOME")
                  ),
                },
              },
            },
          },
        },
      },
    },
  },
}
