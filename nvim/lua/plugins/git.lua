return {
  {
    "pwntester/octo.nvim",
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
