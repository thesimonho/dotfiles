vim.lsp.set_log_level("ERROR")

return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
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
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      vim.list_extend(keys, {
        { "<leader>cR", false },
        {
          "<leader>fR",
          Snacks.rename.rename_file,
          desc = "Rename File",
          mode = { "n" },
          has = { "workspace/didRenameFiles", "workspace/willRenameFiles" },
        },
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
        enabled = true,
      },
      codelens = {
        enabled = false,
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
  {
    "zeioth/garbage-day.nvim",
    dependencies = "neovim/nvim-lspconfig",
    event = "VeryLazy",
    opts = {
      grace_period = 60 * 15, --seconds
      wakeup_delay = 2000, --milliseconds
    },
  },
}
