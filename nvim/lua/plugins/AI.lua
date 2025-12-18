local constants = require("config.constants")

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
    "olimorris/codecompanion.nvim",
    event = "LazyFile",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/codecompanion-history.nvim",
      "franco-ruggeri/codecompanion-spinner.nvim",
    },
    keys = {
      { "<leader>ac", "<cmd>CodeCompanionChat Toggle adapter=copilot<cr>", mode = "n", desc = "Chat" },
      { "<leader>aa", "<cmd>CodeCompanionChat Toggle adapter=codex<cr>", mode = "n", desc = "Agent" },
      { "<leader>an", "<cmd>CodeCompanionChat<cr>", desc = "New Chat" },
      { "<leader>ae", "<cmd>CodeCompanion<cr>", mode = "v", desc = "Edit Inline" },
      { "<leader>ah", "<cmd>CodeCompanionHistory<cr>", desc = "Chat History" },
    },
    opts = {
      display = {
        chat = {
          auto_scroll = true,
          intro_message = "",
          start_in_insert_mode = false,
          show_settings = true,
          window = {
            border = "rounded",
            width = 0.5,
          },
        },
      },
      adapters = {
        http = {
          opts = {
            show_presets = false,
          },
        },
        acp = {
          opts = {
            show_presets = false,
          },
          codex = function()
            return require("codecompanion.adapters").extend("codex", {
              defaults = {
                auth_method = "chatgpt",
              },
            })
          end,
          claude_code = function()
            return require("codecompanion.adapters").extend("claude_code", {
              env = {
                CLAUDE_CODE_OAUTH_TOKEN = "CLAUDE_CODE_OAUTH_TOKEN", -- set this in env var using token value from claude code oauth
              },
            })
          end,
        },
      },
      interactions = {
        chat = {
          adapter = {
            name = "copilot",
            model = "gpt-5.1",
          },
          opts = {
            goto_file_action = "edit",
          },
        },
        inline = {
          adapter = {
            name = "codex",
          },
        },
      },
      extensions = {
        spinner = {},
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
