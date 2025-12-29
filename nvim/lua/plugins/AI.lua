local models = {
  completion = "gpt-41-copilot",
  openai = {
    chat = "gpt-5.2",
    agent = "gpt-5.1-codex-max",
  },
  claude = {
    chat = "claude-sonnet-4-5",
    agent = "claude-sonnet-4-5",
  },
}

local M = {
  {
    "zbirenbaum/copilot.lua",
    dependencies = {
      "copilotlsp-nvim/copilot-lsp",
    },
    cmd = "Copilot",
    event = "InsertEnter",
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
      copilot_model = models.completion,
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
      nes = {
        enabled = true,
        keymap = {
          accept = false,
          accept_and_goto = "<Tab>",
          dismiss = "<Esc>",
        },
      },
    },
  },
  -- NOTE: we can maybe replace this with sidekick.nvim for agents, browser for chat, and cancel copilot (windsurf for completions?)
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
      { "<leader>aa", "<cmd>CodeCompanionChat Toggle adapter=claude_code<cr>", mode = "n", desc = "Agent" },
      { "<leader>an", "<cmd>CodeCompanionChat<cr>", desc = "New Chat" },
      {
        "<leader>ae",
        function()
          local keys = vim.api.nvim_replace_termcodes(":CodeCompanion ", true, false, true)
          vim.api.nvim_feedkeys(keys, "n", false)
        end,
        mode = "v",
        desc = "Edit Inline",
      },
      { "<leader>ah", "<cmd>CodeCompanionHistory<cr>", desc = "Chat History" },
    },
    opts = {
      display = {
        chat = {
          auto_scroll = true,
          intro_message = "",
          start_in_insert_mode = false,
          show_settings = false,
          show_reasoning = false,
          fold_reasoning = true,
          window = {
            layout = "float",
            border = "rounded",
            width = 0.8,
            height = 0.8,
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
              schema = {
                model = {
                  default = models.openai.agent,
                },
              },
            })
          end,
          claude_code = function()
            return require("codecompanion.adapters").extend("claude_code", {
              env = {
                CLAUDE_CODE_OAUTH_TOKEN = vim.env.CLAUDE_CODE_OAUTH_TOKEN, -- token value from claude setup-token
              },
              schema = {
                model = {
                  default = models.claude.agent,
                },
              },
            })
          end,
        },
      },
      interactions = {
        chat = {
          adapter = {
            name = "copilot",
            model = models.claude.chat,
          },
          tools = {
            opts = {
              default_tools = {
                "full_stack_dev",
              },
            },
          },
          opts = {
            goto_file_action = "edit",
          },
        },
        inline = {
          adapter = {
            name = "copilot",
            model = models.claude.chat,
          },
          tools = {
            opts = {
              default_tools = {
                "full_stack_dev",
              },
            },
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
              adapter = "copilot",
              model = models.chat,
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
