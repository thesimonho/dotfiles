return {
  "chrisgrieser/nvim-spider",
  vscode = true,
  keys = {
    { "w", "<cmd>lua require('spider').motion('w')<CR>", mode = { "n", "o", "x" } },
    { "e", "<cmd>lua require('spider').motion('e')<CR>", mode = { "n", "o", "x" } },
    { "b", "<cmd>lua require('spider').motion('b')<CR>", mode = { "n", "o", "x" } },
  },
  opts = {
    skipInsignificantPunctuation = true,
    subwordMovement = true,
    customPatterns = {},
  },
}
