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
    "folke/sidekick.nvim",
    opts = {
      nes = {
        enabled = false,
        debounce = 2000,
        diff = {
          inline = false,
        },
      },
      cli = {
        win = {
          layout = "float",
          float = {
            width = 0.8,
            height = 0.8,
            border = constants.border_chars_outer_thin,
          },
        },
        mux = {
          enabled = false,
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
      { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", mode = "n", desc = "Chat" },
      { "<leader>aa", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "Add to Chat" },
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
          show_settings = false,
          window = {
            border = "rounded",
            width = 0.5,
          },
        },
      },
      adapters = {
        acp = {
          opts = {
            show_presets = false,
          },
          codex = function()
            return require("codecompanion.adapters").extend("codex", {
              commands = {
                default = {
                  "npx",
                  "@zed-industries/codex-acp",
                },
              },
              defaults = {
                auth_method = "chatgpt",
                timeout = 30000,
              },
            })
          end,
        },
        http = {
          opts = {
            show_presets = false,
          },
        },
      },
      interactions = {
        chat = {
          adapter = {
            name = "copilot",
            model = "gpt-5.1",
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
