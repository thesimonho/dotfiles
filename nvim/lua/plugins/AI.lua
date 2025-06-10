vim.g.ai_cmp = true -- show AI suggestions in cmp

local M = {
  {
    "zbirenbaum/copilot.lua",
    enabled = false,
    keys = {
      {
        "<leader>a.",
        function()
          vim.cmd("Copilot panel")
          vim.cmd("wincmd =")
        end,
        desc = "Copilot suggestion panel",
      },
    },
    opts = {
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
    "CopilotC-Nvim/CopilotChat.nvim",
    enabled = false,
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    build = "make tiktoken",
    init = function()
      local wk = require("which-key")
      wk.add({
        { "<leader>ah", group = "History" },
      })
    end,
    keys = {
      { "<leader>aq", false },
      {
        "<leader>aa",
        function()
          vim.cmd("CopilotChatToggle")
          vim.cmd("wincmd =")
        end,
        mode = { "n", "v" },
        desc = "CopilotChat toggle",
      },
      { "<leader>ax", "<cmd>CopilotChatStop<cr>", desc = "CopilotChat stop" },
      {
        "<leader>ahs",
        function()
          vim.ui.input({ prompt = "Save chat as: " }, function(input)
            if input then
              vim.cmd("CopilotChatSave " .. input)
            end
          end)
        end,
        desc = "CopilotChat save",
      },
      {
        "<leader>ahl",
        function()
          vim.ui.input({ prompt = "Load chat: " }, function(input)
            if input then
              vim.cmd("CopilotChatLoad " .. input)
            end
          end)
        end,
        desc = "CopilotChat load",
      },
      { "<leader>ap", "<cmd>CopilotChatPrompts<cr>", mode = { "n", "v" }, desc = "CopilotChat prompts" },
      { "<leader>aM", "<cmd>CopilotChatModels<cr>", desc = "CopilotChat select model" },
      { "<leader>a@", "<cmd>CopilotChatAgents<cr>", desc = "CopilotChat select agent" },
    },
    opts = {
      model = "gpt-4.1",
      agent = "copilot",
      temperature = 0.1,
      auto_insert_mode = false,
      insert_at_end = true,
      highlight_selection = true,
      highlight_headers = false, -- use rendermarkdown
      separator = "---",
      question_header = "🐼 Simon ",
      answer_header = "  Copilot ",
      error_header = "❌ [!ERROR] Error",
      selection = function(source)
        local select = require("CopilotChat.select")
        return select.visual(source) or select.buffer(source)
      end,
      mappings = {
        reset = {
          normal = "<leader>aR",
          insert = "<C-C>",
        },
        toggle_sticky = {
          normal = "<leader>as",
        },
        clear_stickies = {
          normal = "<leader>aS",
        },
        accept_diff = {
          normal = "<leader>ad",
          insert = "<C-y>",
        },
        jump_to_diff = {
          normal = "gd",
        },
        quickfix_answers = {
          normal = "<leader>aq",
        },
        quickfix_diffs = {
          normal = "<leader>aQ",
        },
        yank_diff = {
          normal = "gy",
          register = '"', -- Default register to use for yanking
        },
        show_diff = {
          normal = "<leader>aD",
          full_diff = true, -- Show full diff instead of unified diff when showing diff window
        },
      },
    },
  },
  {
    "AlejandroSuero/supermaven-nvim", -- TODO: fork until PR is merged
    enabled = true,
    lazy = false, -- required otherwise color setting wont work
    branch = "feature/exposing-suggestion-group",
    init = function()
      require("snacks").toggle
        .new({
          name = "Supermaven",
          get = function()
            return require("supermaven-nvim.api").is_running()
          end,
          set = function()
            require("supermaven-nvim.api").toggle()
          end,
        })
        :map("<leader>ux")
    end,
    opts = {
      ignore_filetypes = { "neo-tree", "neo-tree-popup", "AvanteInput", "AvantePromptInput" },
      keymaps = {
        accept_suggestion = "<M-l>",
        accept_word = "<M-h>",
        clear_suggestion = "<M-e>",
      },
      color = {
        suggestion_group = "Comment",
      },
      disable_inline_completion = vim.g.ai_cmp,
    },
  },
  {
    "yetone/avante.nvim",
    enabled = true,
    build = "make",
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "saghen/blink.cmp",
        dependencies = {
          "Kaiser-Yang/blink-cmp-avante",
        },
        opts = {
          enabled = function()
            return not vim.tbl_contains({ "AvanteInput", "AvantePromptInput" }, vim.bo.filetype)
          end,
          sources = {
            default = {
              "avante",
            },
            providers = {
              avante = {
                module = "blink-cmp-avante",
                name = "avante",
              },
            },
          },
        },
      },
      {
        "nvim-neo-tree/neo-tree.nvim",
        opts = {
          filesystem = {
            commands = {
              avante_add_files = function(state)
                local node = state.tree:get_node()
                local filepath = node:get_id()
                local relative_path = require("avante.utils").relative_path(filepath)

                local sidebar = require("avante").get()

                local open = sidebar:is_open()
                -- ensure avante sidebar is open
                if not open then
                  require("avante.api").ask()
                  sidebar = require("avante").get()
                end

                sidebar.file_selector:add_selected_file(relative_path)

                -- remove neo tree buffer
                if not open then
                  sidebar.file_selector:remove_selected_file("neo-tree filesystem [1]")
                end
              end,
            },
            window = {
              mappings = {
                ["@"] = "avante_add_files",
              },
            },
          },
        },
      },
    },
    init = function()
      local wk = require("which-key")
      wk.add({
        mode = { "n", "v" },
        { "<leader>a", group = "AI" },
      }, {
        mode = "n",
        { "<leader>ac", group = "Choose change" },
      })
    end,
    keys = {
      { "<leader>aC", "<cmd>AvanteClear<cr>", desc = "avante: clear session" },
    },
    opts = {
      -- mode = "agentic",
      mode = "legacy",
      provider = "openai",
      auto_suggestions_provider = "qwen_coder_2.5",
      cursor_applying_provider = "openai",
      memory_summary_provider = "openai",
      selector = {
        provider = "snacks",
      },
      file_selector = {
        provider = "snacks",
      },
      behaviour = {
        auto_focus_sidebar = true,
        auto_suggestions = false, -- Experimental stage
        auto_suggestions_respect_ignore = true,
        auto_apply_diff_after_generation = false,
        use_cwd_as_project_root = true,
        enable_cursor_planning_mode = true,
        enable_claude_text_editor_tool_mode = true,
      },
      hints = {
        enabled = false,
      },
      windows = {
        wrap = true,
        edit = {
          border = "rounded",
        },
        ask = {
          border = "rounded",
          start_insert = false,
        },
      },
      rag_service = {
        enabled = false,
        host_mount = os.getenv("HOME"),
        provider = "ollama", -- The provider to use for RAG service (e.g. openai or ollama)
        llm_model = "granite3.1-dense:8b", -- The LLM model to use for RAG service
        embed_model = "granite-embedding:30m", -- The embedding model to use for RAG service
        endpoint = "http://localhost:11435",
      },
      web_search_engine = {
        provider = "tavily",
        proxy = nil,
        providers = {
          tavily = {
            api_key_name = os.getenv("TAVILY_API_KEY"),
          },
        },
      },
      providers = {
        openai = {
          endpoint = "https://api.openai.com/v1",
          model = "gpt-4.1",
          timeout = 30000, -- Timeout in milliseconds, increase this for reasoning models
          extra_request_body = {
            temperature = 0.1,
            max_completion_tokens = 8192, -- Increase this to include reasoning tokens (for reasoning models)
            reasoning_effort = "medium", -- low|medium|high, only used for reasoning models
            disable_tools = false,
          },
        },
        ollama = {
          endpoint = "http://127.0.0.1:11435",
          timeout = 30000, -- Timeout in milliseconds
          extra_request_body = {
            options = {
              temperature = 0.1,
              num_ctx = 20480,
              keep_alive = "5m",
            },
          },
        },
        ["qwen_coder_2.5"] = {
          __inherited_from = "ollama",
          model = "qwen2.5-coder:3b",
          temperature = 0.1,
          max_tokens = 8192,
        },
      },
      mappings = {
        files = {
          add_current = "<leader>ab", -- Add current buffer to selected files
          add_all_buffers = "<leader>aB", -- Add all buffer files to selected files
        },
        diff = {
          ours = "<leader>aco",
          theirs = "<leader>act",
          all_theirs = "<leader>acT",
          both = "<leader>acb",
          cursor = "<leader>acc",
        },
        suggestion = {
          accept = "<M-l>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<M-e>",
        },
      },
    },
  },
}

return M
