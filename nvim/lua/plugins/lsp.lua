return {
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
      enabled = false,
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
    event = "VeryLazy",
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
