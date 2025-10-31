local M = {
  {
    "zbirenbaum/copilot.lua",
    dependencies = {
      "copilotlsp-nvim/copilot-lsp",
    },
    keys = {
      {
        "<leader>ad",
        function()
          vim.cmd("Copilot disable")
        end,
        desc = "Disable Copilot",
      },
    },
    opts = {
      copilot_model = "gpt-4o",
      suggestion = {
        enabled = not vim.g.ai_cmp,
        auto_trigger = true,
        trigger_on_accept = true,
        hide_during_completion = vim.g.ai_cmp,
        keymap = {
          accept = "<M-l>",
          accept_word = "<M-h>",
          accept_line = false,
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-e>",
        },
      },
    },
  },
  {
    "folke/sidekick.nvim",
    keys = {
      { "<leader>aa", vim.NIL },
      { "<leader>ac", vim.NIL },
      {
        "<tab>",
        function()
          if require("sidekick.nes").have() then
            require("sidekick.nes").apply()
          else
            require("sidekick.nes").update()
          end
        end,
        mode = "n",
      },
    },
    opts = {
      cli = {
        mux = {
          enabled = false,
        },
      },
      nes = {
        enabled = true,
      },
    },
  },
  {
    "olimorris/codecompanion.nvim",
    event = "LazyFile",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/codecompanion-history.nvim",
    },
    keys = {
      { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", mode = "n", desc = "Chat" },
      { "<leader>aa", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "Add to Chat" },
      { "<leader>an", "<cmd>CodeCompanionChat<cr>", desc = "New Chat" },
      { "<leader>ae", "<cmd>CodeCompanion<cr>", mode = "v", desc = "Edit Inline" },
      { "<leader>ap", "<cmd>CodeCompanionActions<cr>", desc = "Actions Palette" },
      { "<leader>ah", "<cmd>CodeCompanionHistory<cr>", desc = "Chat History" },
    },
    opts = {
      display = {
        chat = {
          auto_scroll = true,
          intro_message = "",
          start_in_insert_mode = false,
          show_settings = false,
          window = {
            border = "rounded",
            width = 0.4,
          },
        },
      },
      strategies = {
        chat = {
          adapter = {
            name = "copilot",
            model = "gpt-5",
          },
          tools = {
            opts = {
              auto_submit_errors = true,
              auto_submit_success = true,
              default_tools = {},
            },
          },
          opts = {
            goto_file_action = "edit",
          },
        },
        inline = {
          adapter = {
            name = "copilot",
            model = "claude-3.7-sonnet-thought",
          },
          tools = {
            opts = {
              default_tools = {
                "full_stack_dev",
              },
            },
          },
        },
        cmd = {
          adapter = {
            name = "copilot",
            model = "gpt-5-mini",
          },
        },
      },
      extensions = {
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            show_result_in_chat = true, -- Show mcp tool results in chat
            make_vars = true, -- Convert resources to #variables
            make_slash_commands = true, -- Add prompts as /slash commands
          },
        },
        history = {
          enabled = true,
          opts = {
            auto_save = true,
            expiration_days = 60,
            picker_keymaps = {
              rename = { n = "r", i = "<M-r>" },
              delete = { n = "d", i = "<M-d>" },
              duplicate = { n = "<C-y>", i = "<C-y>" },
            },
            auto_generate_title = true,
            title_generation_opts = {
              refresh_every_n_prompts = 5,
              max_refreshes = 3,
            },
            continue_last_chat = false,
            delete_on_clearing_chat = false,
          },
        },
      },
    },
  },
  {
    "ravitemer/mcphub.nvim",
    build = "npm install -g mcp-hub@latest",
    lazy = true,
    cmd = "MCPHub",
    keys = {
      { "<leader>am", "<cmd>MCPHub<cr>", desc = "MCP Hub" },
    },
    init = function()
      local wk = require("which-key")
      wk.add({
        mode = { "n", "v" },
        { "<leader>a", group = "AI" },
      })
    end,
    opts = {
      auto_approve = true,
    },
  },
}

return M
