return {
  "nvim-pack/nvim-spectre",
  keys = {
    { "<leader>sr", vim.NIL },
    {
      "<leader>cR",
      function()
        require("spectre").open()
      end,
      desc = "Search & Replace",
    },
  },
}
