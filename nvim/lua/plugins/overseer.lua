return {
  "stevearc/overseer.nvim",
  lazy = true,
  cmd = {
    "OverseerToggle",
    "OverseerRun",
    "OverseerOpen",
    "OverseerLoadBundle",
    "OverseerBuild",
    "OverseerInfo",
    "OverseerTaskAction",
  },
  keys = {
    { "<F5>", "<cmd>OverseerToggle<cr>", desc = "Overseer" },
    { "<C-F5>", "<cmd>OverseerRun<cr>", desc = "Overseer Run" },
  },
  opts = {
    strategy = {
      "toggleterm",
      use_shell = false,
      auto_scroll = true,
      close_on_exit = false,
      open_on_start = true,
      hidden = false,
    },
    templates = { "builtin", "scripts", "python", "go" },
  },
}
