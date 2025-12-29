local M = {
  {
    "supermaven-inc/supermaven-nvim",
    dependencies = { "folke/snacks.nvim" },
    event = "InsertEnter",
    init = function()
      require("snacks")
        .toggle({
          name = "AI Completions",
          get = function()
            return require("supermaven-nvim.api").is_running() or false
          end,
          set = function()
            require("supermaven-nvim.api").toggle()
          end,
        })
        :map("<leader>ux")
    end,
    opts = {
      keymaps = {
        accept_suggestion = "<M-l>",
        clear_suggestion = "<C-e>",
        accept_word = "<M-h>",
      },
      ignore_filetypes = { "bigfile", "snacks_input", "snacks_notif" },
      color = {
        cterm = 244,
      },
      log_level = "off",
    },
  },
  {
    "folke/sidekick.nvim",
    opts = {
      cli = {
        watch = true,
        win = {
          layout = "float",
        },
        mux = {
          enabled = false,
        },
      },
      nes = {
        enabled = false,
      },
    },
  },
}

return M
