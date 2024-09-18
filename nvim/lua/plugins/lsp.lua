vim.lsp.set_log_level("ERROR")

return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "graphql-language-service-cli",
        "marksman",
        "mdx-analyzer",
        "lua-language-server",
        "pyright",
        "ruff-lsp",
        "terraform-ls",
        "vim-language-server",
        "yaml-language-server",
        "vue-language-server",
      })
    end,
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
        exclude = {},
      },
      codelens = {
        enabled = true,
      },
      document_highlight = {
        enabled = true,
      },
      capabilities = {
        textDocument = {
          foldingRange = {
            dynamicRegistration = false,
            lineFoldingOnly = true,
          },
        },
      },
    },
  },
}
