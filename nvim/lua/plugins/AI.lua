return {
  "Exafunction/codeium.vim",
  event = "BufEnter",
  cmd = "Codeium",
  build = ":Codeium Auth",
  config = function()
    vim.g.codeium_disable_bindings = 1
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
      "<leader>zc",
      function()
        return vim.fn["codeium#Chat"]()
      end,
      desc = "Codeium chat",
    },
  },
}
