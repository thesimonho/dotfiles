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
    direction = "float",
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

local function show_agent_terminal()
  local t = open_agents[next(open_agents or {})]
  if t and not t:is_open() then
    t:open()
  end
end

vim.keymap.set("v", "<leader>as", function()
  vim.cmd("'<,'>ToggleTermSendVisualSelection 5")
  show_agent_terminal()
end, { noremap = true, silent = true, desc = "Send selection to agent terminal" })

local function set_tabby_lifecycle_state(lifecycle_state)
  local is_ready = lifecycle_state == "ready"
  vim.g.tabby_inline_completion_trigger = is_ready and "auto" or "manual"

  if not is_ready then
    -- Container startup can fail before lazy.nvim has sourced vim-tabby's autoload functions.
    pcall(vim.fn["tabby#inline_completion#service#Clear"])
    vim.lsp.enable("tabby", false)
    return
  end

  vim.lsp.enable("tabby", true)
end

local tabby_lsp_init_options = {
  clientCapabilities = {
    textDocument = {
      inlineCompletion = true,
    },
  },
}

local function trigger_tabby_attached_event()
  vim.api.nvim_exec_autocmds("User", { pattern = "tabby_lsp_on_buffer_attached" })
end

local function configure_native_tabby_lsp()
  vim.lsp.config("tabby", {
    cmd = vim.g.tabby_agent_start_command,
    root_markers = { ".git" },
    init_options = tabby_lsp_init_options,
    on_attach = trigger_tabby_attached_event,
  })
end

local function configure_tabby_inline_completion_request()
  local tabby_lsp = require("tabby.lsp.nvim_lsp")

  function tabby_lsp.request_inline_completion(params)
    local client = vim.lsp.get_clients({ name = "tabby" })[1]
    if not client then
      return 0
    end

    local request_params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    request_params.context = { triggerKind = params.trigger_kind }

    local request_id
    _, request_id = client:request("textDocument/inlineCompletion", request_params, function(_, result)
      vim.fn["tabby#lsp#nvim_lsp#CallInlineCompletionCallback"](request_id, result)
    end)
    return request_id
  end

  vim.cmd("let g:tabby_lsp_client = tabby#lsp#nvim_lsp#GetClient()")
  vim.fn["tabby#inline_completion#Setup"]()

  local function install_tabby_inline_completion()
    vim.fn["tabby#inline_completion#Install"]()
    vim.keymap.set("i", "<M-l>", function()
      return vim.fn["tabby#inline_completion#service#Accept"]()
    end, {
      buffer = true,
      expr = true,
      replace_keycodes = true,
      silent = true,
      nowait = true,
      desc = "Accept Tabby suggestion",
    })
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "tabby_lsp_on_buffer_attached",
    callback = install_tabby_inline_completion,
    desc = "Install Tabby inline completion with Neovim keycode handling",
  })

  local is_tabby_attached = #vim.lsp.get_clients({ name = "tabby", bufnr = 0 }) > 0
  if is_tabby_attached then
    install_tabby_inline_completion()
  end
end

local tabby_container = require("utils.compose_service").new({
  name = "Tabby",
  compose_file = "~/dotfiles/AI/tabby.yaml",
  service = "tabby",
  docker_context = "default",
  wait_for_health = true,
  poll_timeout_ms = 120000,
  session_scoped = true,
  on_state_change = set_tabby_lifecycle_state,
})

local M = {
  {
    "TabbyML/vim-tabby",
    event = "VeryLazy",
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = {
          ensure_installed = {
            "tabby-agent",
          },
        },
      },
    },
    init = function()
      -- Use the upstream inline UI without its legacy nvim-lspconfig setup.
      vim.g.loaded_tabby = 1
      vim.g.tabby_agent_start_command = { "tabby-agent", "--stdio" }
      vim.g.tabby_inline_completion_trigger = "auto"
      vim.g.tabby_inline_completion_keybinding_accept = "<M-l>"
      configure_native_tabby_lsp()

      tabby_container:set_running(true)

      local tabby_container_group = vim.api.nvim_create_augroup("tabby_container", { clear = true })
      vim.api.nvim_create_autocmd("FocusGained", {
        group = tabby_container_group,
        callback = function()
          tabby_container:refresh()
        end,
        desc = "Refresh Tabby container state",
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          vim.schedule(function()
            require("snacks")
              .toggle({
                name = "AI Suggestions",
                get = function()
                  return tabby_container:is_enabled()
                end,
                set = function(is_enabled)
                  tabby_container:set_running(is_enabled)
                end,
              })
              :map("<leader>ul")
          end)
        end,
      })
    end,
    config = configure_tabby_inline_completion_request,
  },
  {
    "supermaven-inc/supermaven-nvim",
    enabled = false,
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
      ignore_filetypes = { "bigfile", "neo-tree-popup", "snacks_picker_input", "snacks_input", "snacks_notif" },
      color = {
        cterm = 244,
      },
      log_level = "off",
    },
  },
}

return M
