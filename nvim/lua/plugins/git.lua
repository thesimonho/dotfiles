return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>gi",
        function()
          Snacks.picker.gh_issue()
        end,
        desc = "GitHub Issues (open)",
      },
      {
        "<leader>gp",
        function()
          Snacks.picker.gh_pr()
        end,
        desc = "GitHub Pull Requests (open)",
      },
    },
    opts = {
      gitbrowse = {
        notify = true,
        remote_patterns = {
          { "^(https?://.*)%.git$", "%1" },
          { "^git@personal%-github%.com:(.+)%.git$", "https://github.com/%1" },
          { "^git@(.+):(.+)%.git$", "https://%1/%2" },
          { "^git@(.+):(.+)$", "https://%1/%2" },
          { "^git@(.+)/(.+)$", "https://%1/%2" },
          { "^ssh://git@(.*)$", "https://%1" },
          { "^ssh://([^:/]+)(:%d+)/(.*)$", "https://%1/%3" },
          { "^ssh://([^/]+)/(.*)$", "https://%1/%2" },
          { "ssh%.dev%.azure%.com/v3/(.*)/(.*)$", "dev.azure.com/%1/_git/%2" },
          { "^https://%w*@(.*)", "https://%1" },
          { "^git@(.*)", "https://%1" },
          { ":%d+", "" },
          { "%.git$", "" },
        },
      },
      lazygit = {
        configure = true,
        theme = {
          activeBorderColor = { fg = "lualine_b_normal", bold = true },
          inactiveBorderColor = { fg = "Comment" },
          cherryPickedCommitBgColor = { fg = "lualine_b_normal" },
          cherryPickedCommitFgColor = { fg = "Function" },
          defaultFgColor = { fg = "Normal" },
          optionsTextColor = { fg = "Statement" },
          searchingActiveBorderColor = { fg = "Search", bold = true },
          selectedLineBgColor = { bg = "CursorLineAlt" },
          unstagedChangesColor = { fg = "DiagnosticError" },
        },
      },
    },
  },
  {
    "pwntester/octo.nvim",
    enabled = false,
    event = "LazyFile",
    cmd = "Octo",
    ft = "octo",
    init = function()
      vim.treesitter.language.register("markdown", "octo")
    end,
    keys = {
      { "@", vim.NIL, mode = "i", ft = "octo", silent = true, buffer = true },
      { "#", vim.NIL, mode = "i", ft = "octo", silent = true, buffer = true },
    },
    opts = {
      ssh_aliases = { ["personal-github.com"] = "github.com" },
      use_local_fs = false,
      default_to_projects_v2 = false,
      default_remote = { "origin", "upstream" },
      picker = "snacks",
    },
  },
}
