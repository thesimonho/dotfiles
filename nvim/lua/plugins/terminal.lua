local general = require("utils.general")
local os_utils = require("utils.os")
local fs = require("utils.fs")
local wk = require("which-key")

local function set_shell()
  local preferred_shells = { "zsh", "nu", "cmd" }
  for _, shell in ipairs(preferred_shells) do
    if vim.fn.executable(shell) == 1 then
      return shell
    end
  end
end

local function term_or_exec(term_num)
  term_num = term_num or 1
  if fs.has_container() and not os_utils.is_container() then
    local path = fs.get_path_components(vim.fn.getcwd())
    local container_name = path[#path]:lower():gsub("[ _]", "-")
    local cmd = "ssh " .. container_name .. ".devpod"
    vim.notify_once("Launching devcontainer: " .. container_name, vim.log.levels.INFO)
    return term_num .. "TermExec cmd='" .. cmd .. "' go_back=0 direction='float'"
  end
  return term_num .. "ToggleTerm direction='float'"
end

local function is_togglterm_buffer(bufnr)
  local buftype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  return buftype == "toggleterm"
end

local function parse_toggleterm_buffer_info(bufnr)
  local buf_name = vim.api.nvim_buf_get_name(bufnr)
  local cmd, id = buf_name:match("//%d+:(.-);#toggleterm#(.+)$")
  return cmd, tonumber(id)
end

-- check if toggleterm buffer exists. If not then create one
local function init_or_toggle()
  local used_ids = {}
  local toggleterm_exists = false
  local buffers = vim.api.nvim_list_bufs()
  for _, bufnr in ipairs(buffers) do
    if is_togglterm_buffer(bufnr) then
      local cmd, id = parse_toggleterm_buffer_info(bufnr)
      used_ids[#used_ids + 1] = id

      if id and cmd and cmd ~= "claude" and cmd ~= "codex" then
        toggleterm_exists = true
        -- cant break this. we need to get all used ids
      end
    end
  end

  if toggleterm_exists then
    vim.cmd("ToggleTermToggleAll")
    return
  end

  table.sort(used_ids)
  vim.cmd(term_or_exec(general.find_first_unused_number(used_ids)))
end

local function create_terminal_keys(count)
  count = count or 4
  local keys = {}
  for i = 1, count do
    keys[#keys + 1] = {
      "",
      function()
        vim.cmd(term_or_exec(i))
      end,
      desc = "Terminal " .. i,
    }
  end

  keys = vim.list_slice(keys, 1, 10)
  for i, v in ipairs(keys) do
    v[1] = tostring(i)
  end
  return keys
end

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec", "TermSelect", "ToggleTermToggleAll" },
    keys = {
      { "<leader>\\\\", init_or_toggle, desc = "Toggle all" },
      { "<leader>\\s", "<cmd>TermSelect<CR>", desc = "Select" },
    },
    init = function()
      wk.add({
        "<leader>\\",
        group = "terminals",
        expand = function()
          return create_terminal_keys(4)
        end,
      })
    end,
    opts = {
      autochdir = true,
      auto_scroll = true,
      direction = "vertical",
      shell = set_shell(),
      start_in_insert = true,
      hide_numbers = false,
      shade_terminals = false,
      persist_mode = true,
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
    },
  },
}
