local agents = {
  { cmd = "codex", bin = "codex", label = "Codex" },
  { cmd = "claude --allow-dangerously-skip-permissions", bin = "claude", label = "Claude Code" },
  { cmd = "pi", bin = "pi", label = "Pi" },
}
local available_agents = {}
local open_agents = {}
for _, agent in ipairs(agents) do
  if vim.fn.executable(agent.bin) == 1 then
    available_agents[#available_agents + 1] = agent
  end
end

local function create_agent_terminal(agent)
  local Terminal = require("toggleterm.terminal").Terminal

  local t = Terminal:new({
    count = 5, -- always set to terminal #5
    cmd = agent.cmd,
    display_name = agent.label,
    direction = "tab",
    close_on_exit = true,
    auto_scroll = false,
    hidden = true,
    float_opts = {
      border = "rounded",
    },
    on_open = function(term)
      vim.cmd("startinsert!")
      vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = term.bufnr, silent = true, noremap = true })
    end,
    on_stderr = function(_, job, data, name)
      if not data or #data == 0 then
        return
      end

      local msg = table.concat(data, "\n")
      msg = msg:gsub("%s+$", "")
      if msg == "" then
        return
      end

      vim.notify(msg, vim.log.levels.ERROR, {
        title = string.format("%s (%s)", name, job),
      })
    end,
    on_exit = function()
      open_agents[agent] = nil
    end,
  })
  return t
end

local function get_single_open_agent(open)
  local key, value = next(open)
  if not key then
    return nil
  end

  if next(open_agents, key) ~= nil then
    return nil
  end

  return value
end

local function get_agent_terminal(open, agent)
  local t = open[agent]
  if t then
    return t
  end

  t = create_agent_terminal(agent)
  open_agents[agent] = t
  return t
end

vim.keymap.set({ "n", "i", "v", "t" }, "<C-.>", function()
  local single = get_single_open_agent(open_agents)
  if single then
    single:toggle()
    return
  end

  vim.ui.select(available_agents, {
    prompt = "Select an AI agent",
    format_item = function(agent)
      return string.format("%s", agent.label)
    end,
  }, function(choice)
    if not choice then
      return
    end
    get_agent_terminal(open_agents, choice):toggle()
  end)
end, { noremap = true, silent = true })

local M = {
  {
    "supermaven-inc/supermaven-nvim",
    event = "LazyFile",
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          vim.schedule(function()
            require("snacks")
              .toggle({
                name = "AI Suggestions",
                get = function()
                  return require("supermaven-nvim.api").is_running() or false
                end,
                set = function()
                  require("supermaven-nvim.api").toggle()
                end,
              })
              :map("<leader>ul")
          end)
        end,
      })
    end,
    opts = {
      keymaps = {
        accept_suggestion = "<M-l>",
        clear_suggestion = "<C-e>",
        accept_word = "<M-h>",
      },
      ignore_filetypes = {
        "bigfile",
        "neo-tree-popup",
        "snacks_picker_input",
        "snacks_input",
        "snacks_notif",
        "codecompanion",
      },
      color = {
        cterm = 244,
      },
      log_level = "off",
    },
  },
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          overrides = {
            filetype = {
              codecompanion = {
                win_options = {
                  conceallevel = {
                    rendered = 2,
                  },
                  concealcursor = {
                    rendered = "n",
                  },
                },
              },
            },
          },
        },
      },
    },
    cmd = {
      "CodeCompanionChat",
      "CodeCompanionActions",
    },
    keys = {
      {
        "<leader>aa",
        "<cmd>CodeCompanionChat Toggle<cr>",
        desc = "Agent: Toggle",
      },
      {
        "<leader>an",
        "<cmd>CodeCompanionChat<cr>",
        desc = "Agent: New chat",
      },
      {
        "<leader>ar",
        function()
          local chat

          vim.api.nvim_create_autocmd("User", {
            pattern = "CodeCompanionACPSessionPost",
            once = true,
            callback = function()
              vim.schedule(function()
                require("codecompanion.interactions.chat.slash_commands.keymaps").resume.callback(chat)
              end)
            end,
          })

          chat = require("codecompanion").chat()
        end,
        desc = "Agent: Resume session",
      },
      {
        "<leader>am",
        function()
          local chat = require("codecompanion.interactions.chat").last_chat()

          if not chat or not chat.acp_connection then
            return
          end

          require("codecompanion.interactions.chat.slash_commands.keymaps").acp_session_options.callback(chat)
        end,
        desc = "Agent: Model / reasoning",
      },
      {
        "<leader>ao",
        "<cmd>CodeCompanionActions<cr>",
        desc = "Agent: Actions",
      },
    },
    init = function()
      local function sync_herdr_title(bufnr)
        if not vim.env.HERDR_PANE_ID then
          return
        end

        local chat = require("codecompanion.interactions.chat").buf_get_chat(bufnr)

        if not chat or not chat.title or chat.title == "" then
          return
        end

        local pane = vim.env.HERDR_PANE_ID

        vim.system({
          vim.env.HERDR_BIN_PATH or "herdr",
          "pane",
          "report-metadata",
          pane,
          "--source",
          "custom:codecompanion-title",
          "--applies-to-source",
          "custom:codecompanion.nvim:" .. pane,
          "--display-agent",
          chat.title,
        })
      end

      vim.api.nvim_create_autocmd("BufFilePost", {
        callback = function(args)
          if vim.bo[args.buf].filetype ~= "codecompanion" then
            return
          end

          vim.schedule(function()
            sync_herdr_title(args.buf)
          end)
        end,
      })
    end,
    opts = {
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
                auth_method = "chat-gpt",
              },
            })
          end,
        },
      },
      interactions = {
        chat = {
          adapter = "codex",
          roles = {
            user = "You",
            llm = "Codex",
          },
          opts = {
            context_management = {
              enabled = false,
            },
          },
        },
        background = {
          chat = {
            opts = {
              enabled = false,
            },
          },
        },
        code_review = {
          enabled = false,
        },
      },
      mcp = {
        opts = {
          acp_enabled = false,
        },
      },
      integrations = {
        herdr = {
          enabled = true,
        },
      },
      display = {
        action_palette = {
          provider = "snacks",
          opts = {
            show_preset_prompts = false,
            show_preset_rules = false,
          },
        },
        chat = {
          intro_message = "",
          separator = "",
          show_context = true,
          show_header_separator = false,
          show_token_count = false,
          show_reasoning = true,
          fold_reasoning = true,
          fold_context = true,
          start_in_insert_mode = true,
          window = {
            layout = "vertical",
            position = "right",
            width = 0.4,
            full_height = true,
            opts = {
              breakindent = true,
              linebreak = true,
              wrap = true,
            },
          },
          icons = {
            tool_pending = "○ ",
            tool_in_progress = "◌ ",
            tool_success = "✓ ",
            tool_failure = "✗ ",
          },
        },
        diff = {
          enabled = true,
          threshold_for_chat = 8,
          word_highlights = {
            additions = true,
            deletions = true,
          },
          window = {
            width = function()
              return math.min(140, vim.o.columns - 10)
            end,
            height = function()
              return vim.o.lines - 4
            end,
            opts = {
              number = true,
            },
          },
        },
      },
    },
  },
}

return M
