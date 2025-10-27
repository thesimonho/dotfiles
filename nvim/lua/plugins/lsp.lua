vim.lsp.set_log_level("off") -- Disable LSP logging

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "postgrestools", -- supabase
        "graphql-language-service-cli",
        "vim-language-server",
        "yaml-language-server",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = {
          spacing = 10,
          source = "if_many",
          prefix = "icons",
        },
      },
      inlay_hints = {
        enabled = false,
      },
      codelens = {
        enabled = false,
      },
      document_highlight = {
        enabled = true,
      },
      ["*"] = {
        capabilities = {
          textDocument = {
            foldingRange = {
              -- dynamicRegistration = false,
              lineFoldingOnly = true,
            },
          },
        },
      },
    },
  },
}
