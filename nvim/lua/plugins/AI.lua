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

local inline_completion_namespace = vim.api.nvim_create_namespace("nvim.lsp.inline_completion")
local viewed_tabby_completions = {}

local function timestamp_ms()
  return math.floor(vim.uv.hrtime() / 1000000)
end

local function get_tabby_event_id(item)
  local event_id = item and item.data and item.data.eventId
  if not event_id or not event_id.completionId then
    return nil
  end

  return {
    completionId = event_id.completionId,
    choiceIndex = event_id.choiceIndex,
  }
end

local function notify_tabby_event(client, event)
  client:notify("tabby/telemetry/event", event)
end

local function abandon_tabby_view(bufnr, client_id)
  local view = viewed_tabby_completions[bufnr]
  if view and view.client.id == client_id then
    viewed_tabby_completions[bufnr] = nil
  end
end

local function finish_tabby_view(bufnr, event_type)
  local view = viewed_tabby_completions[bufnr]
  if not view then
    return
  end

  viewed_tabby_completions[bufnr] = nil
  notify_tabby_event(view.client, {
    type = event_type,
    eventId = view.event_id,
    viewId = view.id,
    elapsed = timestamp_ms() - view.displayed_at,
  })
end

local function has_visible_inline_completion(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, inline_completion_namespace, 0, -1, { limit = 1 })
  return #extmarks > 0
end

local function record_tabby_view(client, bufnr, result)
  local items = result and (result.items or result)
  local event_id = type(items) == "table" and get_tabby_event_id(items[1]) or nil
  if not event_id or not has_visible_inline_completion(bufnr) then
    finish_tabby_view(bufnr, "dismiss")
    return
  end

  finish_tabby_view(bufnr, "dismiss")
  local displayed_at = timestamp_ms()
  local raw_completion_id = event_id.completionId:gsub("^cmpl%-", "")
  local view_id = string.format("view-%s-at-%d", raw_completion_id, displayed_at)

  viewed_tabby_completions[bufnr] = {
    client = client,
    displayed_at = displayed_at,
    event_id = event_id,
    id = view_id,
  }
  notify_tabby_event(client, { type = "view", eventId = event_id, viewId = view_id })
end

local function first_inline_completion(result)
  local items = result and (result.items or result)
  if type(items) ~= "table" or not items[1] then
    return result
  end

  if result.items then
    return vim.tbl_extend("force", result, { items = { items[1] } })
  end
  return { items[1] }
end

local function wrap_tabby_inline_completion_requests(client)
  if client._tabby_analytics_request then
    return
  end

  local original_request = client.request
  client._tabby_analytics_request = original_request
  client.request = function(self, method, params, handler, bufnr)
    if method ~= "textDocument/inlineCompletion" or not handler then
      return original_request(self, method, params, handler, bufnr)
    end

    local function handle_response(err, result, context, config)
      local completion = first_inline_completion(result)
      handler(err, completion, context, config)
      if not err then
        record_tabby_view(self, context.bufnr, completion)
      end
    end

    return original_request(self, method, params, handle_response, bufnr)
  end
end

local function attach_tabby_analytics(client, bufnr)
  wrap_tabby_inline_completion_requests(client)

  local group = vim.api.nvim_create_augroup("tabby_analytics_" .. bufnr, { clear = true })
  vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      finish_tabby_view(bufnr, "dismiss")
    end,
    desc = "Record dismissed Tabby inline completion",
  })

  vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    buffer = bufnr,
    callback = function(event)
      abandon_tabby_view(bufnr, event.data.client_id)
    end,
    desc = "Clear analytics for detached Tabby client",
  })
end

local function accept_tabby_completion(bufnr)
  return vim.lsp.inline_completion.get({
    bufnr = bufnr,
    on_accept = function(item)
      local view = viewed_tabby_completions[bufnr]
      local event_type = view and view.client.id == item.client_id and "select" or "dismiss"
      finish_tabby_view(bufnr, event_type)
      return item
    end,
  })
end

local function attach_native_tabby_completion(client, bufnr)
  attach_tabby_analytics(client, bufnr)
  vim.lsp.inline_completion.enable(true, { bufnr = bufnr })

  vim.keymap.set("i", "<M-l>", function()
    return accept_tabby_completion(bufnr) and "" or "<M-l>"
  end, {
    buffer = bufnr,
    expr = true,
    replace_keycodes = true,
    silent = true,
    nowait = true,
    desc = "Accept Tabby suggestion",
  })
end

local function configure_tabby_lsp()
  vim.lsp.config("tabby", {
    cmd = { "tabby-agent", "--stdio" },
    root_markers = { ".git" },
    init_options = {
      clientCapabilities = {
        textDocument = { inlineCompletion = true },
      },
    },
    on_attach = attach_native_tabby_completion,
  })
end

local function dismiss_all_tabby_views()
  for bufnr in pairs(viewed_tabby_completions) do
    finish_tabby_view(bufnr, "dismiss")
  end
end

local function set_tabby_lifecycle_state(lifecycle_state)
  local is_ready = lifecycle_state == "ready"
  if not is_ready then
    dismiss_all_tabby_views()
  end
  vim.lsp.enable("tabby", is_ready)
end

local tabby_service
if require("utils.os").is_darwin() then
  tabby_service = require("utils.process_service").new({
    name = "Tabby",
    command = { "tabby", "serve", "--model", "Qwen2.5-Coder-1.5B", "--device", "metal" },
    health_command = {
      "curl",
      "--fail",
      "--silent",
      "--max-time",
      "5",
      "http://127.0.0.1:8080/metrics",
    },
    poll_timeout_ms = 120000,
    session_scoped = true,
    install_hint = "run `brew install tabbyml/tabby/tabby`",
    slow_start_hint = "Likely downloading models on first run.",
    on_state_change = set_tabby_lifecycle_state,
  })
else
  tabby_service = require("utils.compose_service").new({
    name = "Tabby",
    compose_file = "~/dotfiles/AI/tabby.yaml",
    service = "tabby",
    docker_context = "default",
    wait_for_health = true,
    poll_timeout_ms = 120000,
    session_scoped = true,
    install_hint = "install Docker Engine with the NVIDIA Container Toolkit",
    on_state_change = set_tabby_lifecycle_state,
  })
end

local function configure_tabby_toggle()
  require("snacks")
    .toggle({
      name = "AI Suggestions",
      get = function()
        return tabby_service:is_enabled()
      end,
      set = function(is_enabled)
        tabby_service:set_running(is_enabled)
      end,
    })
    :map("<leader>ul")
end

local M = {
  {
    "mason-org/mason.nvim",
    event = "VeryLazy",
    opts = {
      ensure_installed = { "tabby-agent" },
    },
    init = function()
      configure_tabby_lsp()
      tabby_service:set_running(true)

      local tabby_container_group = vim.api.nvim_create_augroup("tabby_container", { clear = true })
      vim.api.nvim_create_autocmd("FocusGained", {
        group = tabby_container_group,
        callback = function()
          tabby_service:refresh()
        end,
        desc = "Refresh Tabby container state",
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          vim.schedule(configure_tabby_toggle)
        end,
      })
    end,
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
