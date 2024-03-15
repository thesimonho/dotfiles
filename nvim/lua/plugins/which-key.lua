return {
  "folke/which-key.nvim",
  opts = {
    defaults = {
      mode = { "n", "v" },
      ["<leader>`"] = { name = "  terminal" },
      ["<leader><tab>"] = { name = "  tabs" },
      ["<leader>b"] = { name = "  buffer" },
      ["<leader>c"] = { name = "  code" },
      ["<leader>f"] = { name = "  file" },
      ["<leader>g"] = { name = " 󰊢 git" },
      ["<leader>q"] = { name = " 󰩈 quit" },
      ["<leader>s"] = { name = "  search" },
      ["<leader>t"] = { name = "  tests" },
      ["<leader>u"] = { name = " 󰨙 ui" },
      ["<leader>w"] = { name = "  windows" },
      ["<leader>x"] = { name = "  diagnostics" },
      ["<leader>z"] = { name = "  tools" },
    },
    key_labels = {
      ["<space>"] = "SPC",
      ["<cr>"] = "RET",
      ["<tab>"] = "TAB",
    },
    icons = {
      group = "",
    },
  },
}
