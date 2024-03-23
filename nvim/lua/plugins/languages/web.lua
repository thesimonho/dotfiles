local util = require("lspconfig.util")

local function get_typescript_server_path(root_dir)
  local global_ts = vim.fn.expand("$LOCALAPPDATA")
    .. "\\nvim-data\\mason\\packages\\typescript-language-server\\node_modules\\typescript\\lib"
  local found_ts = ""
  local function check_dir(path)
    found_ts = util.path.join(path, "node_modules", "typescript", "lib")
    if util.path.exists(found_ts) then
      return path
    end
  end
  if util.search_ancestors(root_dir, check_dir) then
    return found_ts
  else
    return global_ts
  end
end

return {
  {
    "folke/which-key.nvim",
    opts = {
      defaults = {
        ["<localleader>n"] = { name = "  npm" },
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
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tsserver = {},
        volar = {},
      },
      setup = {
        tsserver = function(_, opts)
          require("lspconfig").tsserver.setup({
            init_options = {
              plugins = {
                {
                  name = "@vue/typescript-plugin",
                  location = vim.fn.expand("$LOCALAPPDATA")
                    .. "\\nvim-data\\mason\\packages\\vue-language-server\\node_modules\\@vue\\language-server",
                  languages = { "vue" },
                },
              },
            },
            filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
          })
          return true
        end,
        volar = function(_, opts)
          require("lspconfig").volar.setup({
            filetypes = { "vue" },
            root_dir = util.root_pattern("package.json"),
            init_options = {
              vue = {
                hybridMode = true, -- hybrid mode uses volar for html/css sections, and tsserver for js/ts
              },
              typescript = {
                tsdk = get_typescript_server_path(vim.fn.getcwd()),
              },
            },
          })
          return true
        end,
      },
    },
  },
}
