local M = {}

local inline_completion_namespace = vim.api.nvim_create_namespace("nvim.lsp.inline_completion")
local viewed_completions = {}

local function timestamp_ms()
  return math.floor(vim.uv.hrtime() / 1000000)
end

local function get_event_id(item)
  local event_id = item and item.data and item.data.eventId
  if not event_id or not event_id.completionId then
    return nil
  end

  return {
    completionId = event_id.completionId,
    choiceIndex = event_id.choiceIndex,
  }
end

local function notify(client, event)
  client:notify("tabby/telemetry/event", event)
end

local function abandon_view(bufnr, client_id)
  local view = viewed_completions[bufnr]
  if view and view.client.id == client_id then
    viewed_completions[bufnr] = nil
  end
end

local function finish_view(bufnr, event_type)
  local view = viewed_completions[bufnr]
  if not view then
    return
  end

  viewed_completions[bufnr] = nil
  notify(view.client, {
    type = event_type,
    eventId = view.event_id,
    viewId = view.id,
    elapsed = timestamp_ms() - view.displayed_at,
  })
end

local function has_visible_completion(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, inline_completion_namespace, 0, -1, { limit = 1 })
  return #extmarks > 0
end

local function record_view(client, bufnr, result)
  local items = result and (result.items or result)
  local event_id = type(items) == "table" and get_event_id(items[1]) or nil
  if not event_id or not has_visible_completion(bufnr) then
    finish_view(bufnr, "dismiss")
    return
  end

  finish_view(bufnr, "dismiss")
  local displayed_at = timestamp_ms()
  local raw_completion_id = event_id.completionId:gsub("^cmpl%-", "")
  local view_id = string.format("view-%s-at-%d", raw_completion_id, displayed_at)

  viewed_completions[bufnr] = {
    client = client,
    displayed_at = displayed_at,
    event_id = event_id,
    id = view_id,
  }
  notify(client, { type = "view", eventId = event_id, viewId = view_id })
end

local function first_completion(result)
  local items = result and (result.items or result)
  if type(items) ~= "table" or not items[1] then
    return result
  end

  if result.items then
    return vim.tbl_extend("force", result, { items = { items[1] } })
  end
  return { items[1] }
end

local function wrap_inline_completion_requests(client)
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
      local completion = first_completion(result)
      handler(err, completion, context, config)
      if not err then
        record_view(self, context.bufnr, completion)
      end
    end

    return original_request(self, method, params, handle_response, bufnr)
  end
end

function M.attach(client, bufnr)
  wrap_inline_completion_requests(client)

  local group = vim.api.nvim_create_augroup("tabby_analytics_" .. bufnr, { clear = true })
  vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, {
    group = group,
    buffer = bufnr,
    callback = function()
      finish_view(bufnr, "dismiss")
    end,
    desc = "Record dismissed Tabby inline completion",
  })

  vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    buffer = bufnr,
    callback = function(event)
      abandon_view(bufnr, event.data.client_id)
    end,
    desc = "Clear analytics for detached Tabby client",
  })
end

function M.select(bufnr, client_id)
  local view = viewed_completions[bufnr]
  local event_type = view and view.client.id == client_id and "select" or "dismiss"
  finish_view(bufnr, event_type)
end

function M.dismiss_all()
  for bufnr in pairs(viewed_completions) do
    finish_view(bufnr, "dismiss")
  end
end

return M
