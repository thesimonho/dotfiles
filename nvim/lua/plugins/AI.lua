M = {
  "Exafunction/codeium.vim", -- this is the .vim version of the plugin
  tag = "1.8.37",
  event = "LazyFile",
  cmd = "Codeium",
  build = ":Codeium Auth",
  config = function()
    vim.keymap.set("i", "<M-l>", function()
      return vim.fn["codeium#Accept"]()
    end, { expr = true, silent = true })
    vim.keymap.set("i", "<M-RET>", function()
      return vim.fn["codeium#Complete"]()
    end, { expr = true, silent = true })
    vim.keymap.set("n", "<M-c>", function()
      return vim.fn["codeium#Chat"]()
    end, { expr = true, silent = true })
    vim.keymap.set("i", "<C-e>", function()
      return vim.fn["codeium#Clear"]()
    end, { expr = true, silent = true })
  end,
  keys = {
    {
      "<M-j>",
      function()
        return vim.fn["codeium#CycleCompletions"](1)
      end,
      mode = { "i" },
    },
    {
      "<M-k>",
      function()
        return vim.fn["codeium#CycleCompletions"](-1)
      end,
      mode = { "i" },
    },
    {
      "<leader>zC",
      function()
        return vim.fn["codeium#Chat"]()
      end,
      desc = "Codeium chat",
    },
  },
}

vim.g.codeium_disable_bindings = 1
return M
