return {
  {
    "nvim-flutter/flutter-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    ft = { "dart" },
    keys = {
      { "<localleader>x", "<cmd>FlutterRun<cr>", ft = "dart", desc = "Run app" },
      { "<localleader>r", "<cmd>FlutterReload<cr>", ft = "dart", desc = "Reload app" },
      { "<localleader>R", "<cmd>FlutterRestart<cr>", ft = "dart", desc = "Restart project" },
      { "<localleader>q", "<cmd>FlutterQuit<cr>", ft = "dart", desc = "Quit session" },
      { "<localleader>d", "<cmd>FlutterDevices<cr>", ft = "dart", desc = "Select device" },
      { "<localleader>e", "<cmd>FlutterEmulators<cr>", ft = "dart", desc = "Select emulator" },
      { "<localleader>a", "<cmd>FlutterAttach<cr>", ft = "dart", desc = "Attach to app" },
      { "<localleader>D", "<cmd>FlutterDevTools<cr>", ft = "dart", desc = "Start DevTools" },
      { "<localleader>l", "<cmd>FlutterLogToggle<cr>", ft = "dart", desc = "Toggle logs" },
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
