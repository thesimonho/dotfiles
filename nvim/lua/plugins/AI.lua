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
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "sidekick_terminal",
        callback = function()
          vim.keymap.set("t", "<esc>", "<esc>", { buffer = true, silent = true })
        end,
      })
    end,
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

vim.keymap.set("n", "<leader>ac", function()
  vim.fn.system("xdg-open https://www.claude.ai")
end, { desc = "Chat in browser" })

vim.keymap.set("v", "<leader>ac", function()
  -- Yank to system clipboard (+ register)
  vim.cmd('normal! "+y')
  vim.fn.system("xdg-open https://www.claude.ai")
end, { desc = "Yank and open chat" })

return M
