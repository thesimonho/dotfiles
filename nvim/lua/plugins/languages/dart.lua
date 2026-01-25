return {
  {
    "nvim-flutter/flutter-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    ft = { "dart" },
    keys = {
      { "<localleader>x", "<cmd>FlutterRun<cr>", desc = "Run project" },
      { "<localleader>r", "<cmd>FlutterReload<cr>", desc = "Reload project" },
      { "<localleader>R", "<cmd>FlutterRestart<cr>", desc = "Restart project" },
      { "<localleader>q", "<cmd>FlutterQuit<cr>", desc = "Quit session" },
      { "<localleader>d", "<cmd>FlutterDevices<cr>", desc = "Select device" },
      { "<localleader>e", "<cmd>FlutterEmulators<cr>", desc = "Select emulator" },
      { "<localleader>a", "<cmd>FlutterAttach<cr>", desc = "Attach to app" },
      { "<localleader>D", "<cmd>FlutterDevTools<cr>", desc = "Start DevTools" },
      { "<localleader>l", "<cmd>FlutterLogToggle<cr>", desc = "Toggle logs" },
    },
    opts = {
      ui = {
        border = "rounded",
      },
      debugger = {
        enabled = true,
      },
      root_patterns = { ".git", "pubspec.yaml" },
      widget_guides = {
        enabled = true,
      },
      closing_tags = {
        enabled = false,
      },
      lsp = {
        color = {
          enabled = false, -- whether or not to highlight color variables at all
          virtual_text = false,
          virtual_text_str = "■",
        },
        settings = {
          showTodos = true,
          completeFunctionCalls = true,
          renameFilesWithClasses = "prompt",
          enableSnippets = true,
          updateImportsOnRename = true,
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "dart" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        dart = { "dart_format" },
      },
    },
  },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "sidlatau/neotest-dart",
    },
    opts = {
      adapters = {
        ["neotest-dart"] = {},
      },
    },
  },
}
