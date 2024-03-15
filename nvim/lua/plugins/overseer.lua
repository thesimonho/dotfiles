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
    component_aliases = {
      default = {
        { "display_duration" },
        { "on_output_summarize" },
        "on_exit_set_status",
        "on_complete_notify",
        { "on_output_quickfix" },
      },
    },
    templates = { "builtin", "scripts", "python", "go" },
  },
}
