local opts = {
  cache = false,
  dim_inactive = true,
  diag_background = true,
  auto_plugins = true,
  integrations = {
    wezterm = {
      enabled = true,
    },
  },
}

return {
  {
    "thesimonho/kanagawa-paper.nvim",
    lazy = false,
    dev = true,
    branch = "canvas_imported",
    priority = 1000,
    keys = {
      {
        "<leader>zC",
        function()
          for k in pairs(package.loaded) do
            if k:match("^kanagawa%-paper") then
              package.loaded[k] = nil
            end
          end
          require("kanagawa-paper").setup(opts)
          vim.cmd.colorscheme("kanagawa-paper")
        end,
        desc = "Colorscheme Reload",
      },
    },
    opts = opts,
  },
}
