local M = {
  {
    "AlejandroSuero/supermaven-nvim", -- TODO: fork until PR is merged
    lazy = false, -- required otherwise color setting wont work
    branch = "feature/exposing-suggestion-group",
    opts = {
      ignore_filetypes = { "neo-tree", "AvanteInput", "AvantePromptInput" },
      keymaps = {
        accept_suggestion = "<M-l>",
        accept_word = "<M-h>",
        clear_suggestion = "<M-e>",
      },
      color = {
        suggestion_group = "Comment",
      },
      disable_inline_completion = false,
    },
  },
  {
    "yetone/avante.nvim",
    build = "make",
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            use_absolute_path = true,
          },
        },
      },
      {
        "saghen/blink.cmp",
        opts = {
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
    opts = {
      provider = "openai",
      auto_suggestions_provider = "openai",
      cursor_applying_provider = "openai",
      memory_summary_provider = "openai",
      selector = {
        provider = "snacks",
      },
      behaviour = {
        auto_focus_sidebar = true,
        auto_suggestions = false, -- Experimental stage
        support_paste_from_clipboard = true,
        use_cwd_as_project_root = true,
        enable_cursor_planning_mode = true,
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
      openai = {
        endpoint = "https://api.openai.com/v1",
        model = "gpt-4.1",
        timeout = 30000, -- Timeout in milliseconds, increase this for reasoning models
        temperature = 0.1,
        max_completion_tokens = 16384, -- Increase this to include reasoning tokens (for reasoning models)
        reasoning_effort = "medium", -- low|medium|high, only used for reasoning models
      },
      mappings = {
        files = {
          add_current = "<leader>ab", -- Add current buffer to selected files
          add_all_buffers = "<leader>aB", -- Add all buffer files to selected files
        },
        diff = {
          ours = "<leader>aco",
          theirs = "<leader>act",
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

require("snacks").toggle
  .new({
    name = "AI Copilot",
    get = function()
      return require("supermaven-nvim.api").is_running()
    end,
    set = function()
      require("supermaven-nvim.api").toggle()
    end,
  })
  :map("<leader>ux")

return M
