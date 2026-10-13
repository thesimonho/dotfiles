local general = require("utils.general")
local os_utils = require("utils.os")
local fs = require("utils.fs")

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

-- Use live terminal objects: restored buffers and hidden agent terminals do
-- not establish that a regular shell exists.
local function open_terminal()
  local terminals = require("toggleterm.terminal").get_all(true)
  local used_ids = {}
  local existing
  for _, term in ipairs(terminals) do
    used_ids[#used_ids + 1] = term.id
    if not term.hidden then
      if term:is_open() then
        term:focus()
        vim.cmd.startinsert()
        return
      end
      existing = existing or term
    end
  end

  if existing then
    existing:open(nil, "float")
    vim.cmd.startinsert()
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
    "folke/which-key.nvim",
    opts = {
      spec = {
        {
          "<leader>\\",
          group = "terminals",
          expand = function()
            return create_terminal_keys(4)
          end,
        },
      },
    },
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec", "TermSelect", "ToggleTermToggleAll" },
    keys = {
      { "<leader>\\\\", open_terminal, desc = "Open terminal" },
      { "<leader>\\s", "<cmd>TermSelect<CR>", desc = "Select" },
    },
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
