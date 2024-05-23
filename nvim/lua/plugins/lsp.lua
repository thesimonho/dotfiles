vim.lsp.set_log_level("ERROR")

return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "graphql-language-service-cli",
        "gopls",
        "marksman",
        "lua-language-server",
        "pyright",
        "ruff-lsp",
        "terraform-ls",
        "typescript-language-server",
        "vim-language-server",
        "yaml-language-server",
        "vue-language-server",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    init = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      keys[#keys + 1] = { "gd", "<cmd>Glance definitions<cr>" }
      keys[#keys + 1] = { "gr", "<cmd>Glance references<cr>" }
      keys[#keys + 1] = { "gy", "<cmd>Glance type_definitions<cr>" }
      keys[#keys + 1] = { "gI", "<cmd>Glance implementations<cr>" }
    end,
    opts = {
      diagnostics = {
        virtual_text = {
          spacing = 10,
          source = "if_many",
          prefix = "icons",
        },
      },
    },
    inlay_hints = {
      enabled = true,
    },
    codelens = {
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
  {
    "dnlhc/glance.nvim",
    event = "LazyFile",
    opts = {
      preview_win_opts = {
        cursorline = true,
        number = false,
        wrap = true,
      },
      border = {
        enable = true,
        top_char = "―",
        bottom_char = "―",
      },
    },
  },
}
