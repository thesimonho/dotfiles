local wk = require("which-key")

return {
  {
    "vuki656/package-info.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    ft = { "json" },
    init = function()
      wk.add({ "<localleader>n", group = "  npm" })
    end,
    keys = {
      {
        "<localleader>nh",
        ":lua require('package-info').toggle()<CR>",
        ft = "json",
        desc = "Hide dependencies",
      },
      {
        "<localleader>nd",
        ":lua require('package-info').delete()<CR>",
        ft = "json",
        desc = "Delete dependency",
      },
      {
        "<localleader>nu",
        ":lua require('package-info').update()<CR>",
        ft = "json",
        desc = "Update dependency",
      },
      { "<localleader>nc", ":lua require('package-info').change_version()<CR>", ft = "json", desc = "Change version" },
      {
        "<localleader>ni",
        ":lua require('package-info').install()<CR>",
        ft = "json",
        desc = "Install new dependency",
      },
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
  {
    "mistweaverco/kulala.nvim",
    ft = "http",
    init = function()
      wk.add({ "<localleader>r", group = " 󰖟 REST" })
    end,
    keys = {
      { "<localleader>rb", "<cmd>lua require('kulala').scratchpad()<cr>", desc = "Open scratchpad", ft = "http" },
      { "<localleader>rc", "<cmd>lua require('kulala').copy()<cr>", desc = "Copy as cURL", ft = "http" },
      { "<localleader>rC", "<cmd>lua require('kulala').from_curl()<cr>", desc = "Paste from curl", ft = "http" },
      {
        "<localleader>rg",
        "<cmd>lua require('kulala').download_graphql_schema()<cr>",
        desc = "Download GraphQL schema",
        ft = "http",
      },
      {
        "<localleader>ri",
        "<cmd>lua require('kulala').inspect()<cr>",
        desc = "Inspect current request",
        ft = "http",
      },
      {
        "<localleader>rn",
        "<cmd>lua require('kulala').jump_next()<cr>",
        desc = "Jump to next request",
        ft = "http",
      },
      {
        "<localleader>rp",
        "<cmd>lua require('kulala').jump_prev()<cr>",
        desc = "Jump to previous request",
        ft = "http",
      },
      {
        "<localleader>rq",
        "<cmd>lua require('kulala').close()<cr>",
        desc = "Close window",
        ft = "http",
      },
      {
        "<localleader>rr",
        "<cmd>lua require('kulala').replay()<cr>",
        desc = "Replay the last request",
        ft = "http",
      },
      {
        "<localleader>rs",
        "<cmd>lua require('kulala').run()<cr>",
        desc = "Send the request",
        ft = "http",
      },
      {
        "<localleader>rS",
        "<cmd>lua require('kulala').show_stats()<cr>",
        desc = "Show stats",
        ft = "http",
      },
      {
        "<localleader>rt",
        "<cmd>lua require('kulala').toggle_view()<cr>",
        desc = "Toggle headers/body",
        ft = "http",
      },
    },
  },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "marilari88/neotest-vitest",
    },
    opts = {
      adapters = {
        ["neotest-vitest"] = {},
      },
      summary = {
        follow = true,
      },
      output = {
        open_on_run = false,
      },
    },
  },
}
