local agents = {
  { cmd = "claude", label = "Claude Code" },
  { cmd = "codex", label = "Codex" },
}
local available_agents = {}
local open_agents = {}
for _, agent in ipairs(agents) do
  if vim.fn.executable(agent.cmd) == 1 then
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

vim.keymap.set("n", "<leader>ac", function()
  vim.fn.system("xdg-open https://www.claude.ai")
end, { desc = "Chat in browser" })

vim.keymap.set("v", "<leader>ac", function()
  -- Yank to system clipboard (+ register)
  vim.cmd('normal! "+y')
  vim.fn.system("xdg-open https://www.claude.ai")
end, { desc = "Yank and open chat" })

local M = {
  {
    "supermaven-inc/supermaven-nvim",
    dependencies = { "folke/snacks.nvim" },
    event = "InsertEnter",
    init = function()
      require("snacks")
        .toggle({
          name = "AI Completions",
          get = function()
            return require("supermaven-nvim.api").is_running() or false
          end,
          set = function()
            require("supermaven-nvim.api").toggle()
          end,
        })
        :map("<leader>ux")
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
