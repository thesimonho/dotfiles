return {
  "jiaoshijie/undotree",
  dependencies = "nvim-lua/plenary.nvim",
  keys = {
    { "U", "<cmd>lua require('undotree').toggle()<cr>" },
  },
  opts = {
    float_diff = true,
    window = {
      winblend = 6,
    },
  },
}
