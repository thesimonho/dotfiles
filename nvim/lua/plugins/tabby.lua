local analytics = require("tabby.analytics")

local function accept_inline_completion(bufnr)
  return vim.lsp.inline_completion.get({
    bufnr = bufnr,
    on_accept = function(item)
      analytics.select(bufnr, item.client_id)
      return item
    end,
  })
end

local function attach_native_inline_completion(client, bufnr)
  analytics.attach(client, bufnr)
  vim.lsp.inline_completion.enable(true, { bufnr = bufnr })

  vim.keymap.set("i", "<M-l>", function()
    return accept_inline_completion(bufnr) and "" or "<M-l>"
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
    on_attach = attach_native_inline_completion,
  })
end

local function set_tabby_lifecycle_state(lifecycle_state)
  local is_ready = lifecycle_state == "ready"
  if not is_ready then
    analytics.dismiss_all()
  end
  vim.lsp.enable("tabby", is_ready)
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

local function configure_tabby_toggle()
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
end

return {
  "mason-org/mason.nvim",
  event = "VeryLazy",
  opts = {
    ensure_installed = { "tabby-agent" },
  },
  init = function()
    configure_tabby_lsp()
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
        vim.schedule(configure_tabby_toggle)
      end,
    })
  end,
}
