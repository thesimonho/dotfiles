local style = require("utils.style")
vim.g.ai_cmp = false -- show AI suggestions in cmp

local M = {
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    keys = {
      {
        "<leader>as",
        function()
          vim.cmd("Copilot panel")
          vim.cmd("wincmd =")
        end,
        desc = "Suggestions Panel",
      },
    },
    opts = {
      copilot_model = "gpt-4o",
      suggestion = {
        enabled = true,
        auto_trigger = true,
        trigger_on_accept = true,
        keymap = {
          accept = "<M-l>",
          accept_word = "<M-h>",
          accept_line = false,
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-e>",
        },
      },
      panel = {
        enabled = true,
        auto_refresh = true,
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<CR>",
          refresh = "gr",
          open = "<M-CR>",
        },
        layout = {
          position = "right",
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
      "Davidyz/VectorCode",
    },
    keys = {
      { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", mode = "n", desc = "Chat" },
      { "<leader>aa", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "Add to Chat" },
      { "<leader>an", "<cmd>CodeCompanionChat<cr>", desc = "New Chat" },
      { "<leader>ae", "<cmd>CodeCompanion<cr>", mode = "v", desc = "Edit Inline" },
      { "<leader>ap", "<cmd>CodeCompanionActions<cr>", desc = "Actions Palette" },
      { "<leader>ah", "<cmd>CodeCompanionHistory<cr>", desc = "Chat History" },
    },
    init = function()
      vim.api.nvim_create_autocmd({ "User" }, {
        group = vim.api.nvim_create_augroup("CodeCompanionFidgetHooks", { clear = true }),
        pattern = "CodeCompanion*",
        callback = function(request)
          local ignored_events = {
            CodeCompanionHistoryTitleSet = true,
          }

          if (request.match and request.match:find("Chat")) or ignored_events[request.match] then
            return
          end

          local msg
          msg = "[CodeCompanion] " .. request.match:gsub("CodeCompanion", "")

          vim.notify(msg, vim.log.levels.INFO, {
            timeout = 1000,
            keep = function()
              return not vim
                .iter({ "Finished", "Opened", "Hidden", "Closed", "Cleared", "Created", "Set" })
                :fold(false, function(acc, cond)
                  return acc or vim.endswith(request.match, cond)
                end)
            end,
            id = "code_companion_status",
            title = "Code Companion Status",
            opts = function(notif)
              notif.icon = ""
              if vim.endswith(request.match, "Started") then
                notif.icon = style.spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #style.spinner + 1]
              elseif vim.endswith(request.match, "Finished") then
                notif.icon = " "
              end
            end,
          })
        end,
      })
    end,
    opts = {
      display = {
        chat = {
          auto_scroll = true,
          start_in_insert_mode = true,
          show_settings = true,
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
            model = "gpt-4o",
          },
          tools = {
            opts = {
              auto_submit_errors = true,
              auto_submit_success = true,
              default_tools = {
                "vectorcode_toolbox",
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
            model = "gpt-4o",
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
        vectorcode = {
          enabled = true,
          opts = {
            tool_group = {
              enabled = true,
              collapse = true,
              extras = { "file_search" },
            },
            tool_opts = {
              ["*"] = {},
              ls = {},
              vectorise = {},
              query = {
                max_num = { chunk = -1, document = -1 },
                default_num = { chunk = 50, document = 10 },
                include_stderr = false,
                no_duplicate = true,
                chunk_mode = false,
                summarise = {
                  enabled = true,
                  query_augmented = true,
                },
              },
              files_ls = {},
              files_rm = {},
            },
          },
        },
      },
    },
  },
  {
    "Davidyz/VectorCode",
    build = "CC=gcc CXX=g++ uv tool upgrade vectorcode",
    opts = {
      async_opts = {
        exclude_this = true,
        n_query = 1,
        notify = true,
        run_on_register = true,
      },
      async_backend = "default", -- or "lsp"
      exclude_this = true,
      notify = true,
      on_setup = {
        update = true,
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
