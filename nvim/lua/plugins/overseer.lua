return {
  "stevearc/overseer.nvim",
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
      auto_scroll = false,
      close_on_exit = false,
      open_on_start = true,
      hidden = false,
    },
    component_aliases = {
      default = {
        { "display_duration" },
        { "on_output_summarize" },
        { "on_exit_set_status", success_codes = { 0 } },
        { "on_complete_dispose", timeout = 300 },
        { "on_complete_notify", on_change = false },
        { "on_result_diagnostics" },
        { "on_result_diagnostics_quickfix", open = true },
        {
          "on_output_quickfix",
          items_only = true,
          open_on_match = true,
          set_diagnostics = true,
          tail = false,
        },
      },
    },
    templates = { "builtin", "scripts", "python", "go" },
  },
}
