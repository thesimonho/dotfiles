local wk = require("which-key")

local function set_shell()
  local preferred_shells = { "nu", "zsh", "bash", "cmd" }
  for _, shell in ipairs(preferred_shells) do
    if vim.fn.executable(shell) == 1 then
      return shell
    end
  end
end

M = {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec", "TermSelect", "ToggleTermToggleAll" },
    keys = {
      { "<leader>\\\\", "<cmd>ToggleTermToggleAll<CR>", desc = "Toggle all" },
      { "<leader>\\1", "<cmd>1ToggleTerm<CR>", desc = "Terminal 1" },
      { "<leader>\\2", "<cmd>2ToggleTerm<CR>", desc = "Terminal 2" },
      { "<leader>\\3", "<cmd>3ToggleTerm<CR>", desc = "Terminal 3" },
      { "<leader>\\4", "<cmd>4ToggleTerm<CR>", desc = "Terminal 4" },
      { "<leader>\\s", "<cmd>TermSelect<CR>", desc = "Select" },
    },
    init = function()
      wk.add({ "<leader>\\", group = "terminal", icon = "" })
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
        vim.wo.cursorline = false
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

return M
