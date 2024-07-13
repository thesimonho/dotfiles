return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        {
          mode = { "n", "v" },
          { "<localleader>n", group = "  npm" },
        },
      },
    },
  },
  {
    "vuki656/package-info.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    ft = { "json" },
    keys = {
      { "<localleader>nh", ":lua require('package-info').toggle()<CR>", ft = "json", desc = "Hide dependencies" },
      { "<localleader>nd", ":lua require('package-info').delete()<CR>", ft = "json", desc = "Delete dependency" },
      { "<localleader>nu", ":lua require('package-info').update()<CR>", ft = "json", desc = "Update dependency" },
      { "<localleader>nc", ":lua require('package-info').change_version()<CR>", ft = "json", desc = "Change version" },
      { "<localleader>ni", ":lua require('package-info').install()<CR>", ft = "json", desc = "Install new dependency" },
    },
    opts = {
      colors = {
        up_to_date = "#3C4048", -- Text color for up to date dependency virtual text
        outdated = "#d19a66", -- Text color for outdated dependency virtual text
      },
      autostart = true,
      hide_up_to_date = true,
      hide_unstable_versions = true,
      package_manager = "npm",
    },
  },
}
