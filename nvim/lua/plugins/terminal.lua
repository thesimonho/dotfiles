local wk = require("which-key")

local function set_shell()
  local preferred_shells = { "nu", "zsh", "bash", "cmd" }
  for _, shell in ipairs(preferred_shells) do
    if vim.fn.executable(shell) == 1 then
      return shell
    end
  end
end

local function init_or_toggle()
  vim.cmd("ToggleTermToggleAll")

  local buffers = vim.api.nvim_list_bufs()

  -- check if toggleterm buffer exists. If not then create one
  local toggleterm_exists = false
  for _, buf in ipairs(buffers) do
    local buf_name = vim.api.nvim_buf_get_name(buf)
    if buf_name:find("toggleterm#") then
      toggleterm_exists = true
      break
    end
  end

  if not toggleterm_exists then
    vim.cmd([[ exe 1 . "ToggleTerm" ]])
  end
end

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec", "TermSelect", "ToggleTermToggleAll" },
    keys = {
      { "<leader>\\\\", init_or_toggle, desc = "Toggle all" },
      { "<leader>\\1", "<cmd>1ToggleTerm<CR>", desc = "Terminal 1" },
      { "<leader>\\2", "<cmd>2ToggleTerm<CR>", desc = "Terminal 2" },
      { "<leader>\\3", "<cmd>3ToggleTerm<CR>", desc = "Terminal 3" },
      { "<leader>\\4", "<cmd>4ToggleTerm<CR>", desc = "Terminal 4" },
      { "<leader>\\s", "<cmd>TermSelect<CR>", desc = "Select" },
    },
    init = function()
      wk.add({ "<leader>\\", group = "terminal" })
    end,
    opts = {
      autochdir = true,
      auto_scroll = true,
      direction = "vertical",
      shell = set_shell(),
      start_in_insert = true,
      hide_numbers = true,
      shade_terminals = false,
      on_create = function(term)
        vim.keymap.set("t", "<esc>", "<C-\\><C-n>", { silent = true, buffer = term.bufnr })
        vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { silent = true, buffer = term.bufnr })
        vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { silent = true, buffer = term.bufnr })
        vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { silent = true, buffer = term.bufnr })
        vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { silent = true, buffer = term.bufnr })
      end,
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
