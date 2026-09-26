local busy = {}
local timer = vim.uv.new_timer()

local function start_spinner()
  if timer:is_active() then
    return
  end

  timer:start(
    0,
    80,
    vim.schedule_wrap(function()
      require("lualine").refresh({
        scope = "tabpage",
        place = { "statusline" },
        force = true,
      })
    end)
  )
end

local function stop_spinner()
  if next(busy) ~= nil then
    return
  end

  timer:stop()

  require("lualine").refresh({
    scope = "tabpage",
    place = { "statusline" },
    force = true,
  })
end

local group = vim.api.nvim_create_augroup("CodeCompanionLualine", { clear = true })

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "CodeCompanionChatSubmitted",
  callback = function(args)
    busy[args.data.bufnr] = true
    start_spinner()
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = {
    "CodeCompanionChatDone",
    "CodeCompanionChatStopped",
    "CodeCompanionChatClosed",
  },
  callback = function(args)
    busy[args.data.bufnr] = nil
    stop_spinner()
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = group,
  callback = function()
    timer:stop()
    timer:close()
  end,
})

local function spinner()
  if not busy[vim.api.nvim_get_current_buf()] then
    return ""
  end

  return Snacks.util.spinner()
end

local function status()
  local metadata = _G.codecompanion_chat_metadata and _G.codecompanion_chat_metadata[vim.api.nvim_get_current_buf()]

  if not metadata then
    return ""
  end

  local model = metadata.adapter and metadata.adapter.model

  local reasoning = metadata.config_options
    and metadata.config_options.thought_level
    and metadata.config_options.thought_level.current

  if not model then
    return ""
  end

  return reasoning and ("%s · %s"):format(model, reasoning) or model
end

return {
  sections = {
    lualine_a = { spinner },
    lualine_b = {},
    lualine_c = {
      { "filename", path = 0 },
    },
    lualine_x = {
      status,
    },
    lualine_y = {},
    lualine_z = {},
  },
  inactive_sections = {
    lualine_a = { spinner },
    lualine_b = {},
    lualine_c = {
      { "filename", path = 0 },
    },
    lualine_x = {
      status,
    },
    lualine_y = {},
    lualine_z = {},
  },
  filetypes = {
    "codecompanion",
  },
}
