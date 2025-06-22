local os_utils = require("utils.os")
local fs = require("utils.fs")
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "lazyvim.plugins.extras.coding.mini-surround" },
    { import = "lazyvim.plugins.extras.coding.yanky" },
    { import = "lazyvim.plugins.extras.dap.core" },
    { import = "lazyvim.plugins.extras.dap.nlua" },
    { import = "lazyvim.plugins.extras.editor.dial" },
    { import = "lazyvim.plugins.extras.editor.snacks_picker" },
    { import = "lazyvim.plugins.extras.test.core" },
    { import = "lazyvim.plugins.extras.ui.treesitter-context" },
    { import = "lazyvim.plugins.extras.util.octo" },
    { import = "lazyvim.plugins.extras.vscode", enabled = os_utils.has_executable("code") },
    -- languages
    { import = "lazyvim.plugins.extras.lang.go", enabled = os_utils.has_executable("go") },
    { import = "lazyvim.plugins.extras.lang.docker", enabled = os_utils.has_executable("docker") },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.markdown" },
    { import = "lazyvim.plugins.extras.lang.python", enabled = os_utils.has_executable("python") },
    { import = "lazyvim.plugins.extras.lang.tailwind", enabled = fs.has_in_project("tailwind.config.ts") },
    { import = "lazyvim.plugins.extras.lang.terraform", enabled = os_utils.has_executable("terraform") },
    { import = "lazyvim.plugins.extras.lang.typescript", enabled = fs.has_in_project("tsconfig.json") },
    { import = "lazyvim.plugins.extras.lang.vue", enabled = fs.has_in_project("vue.config.ts") },
    { import = "lazyvim.plugins.extras.lang.yaml" },
    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  checker = { enabled = true, frequency = 9000 }, -- automatically check for plugin updates
  change_detection = {
    -- automatically check for config file changes and reload the ui
    enabled = false,
    notify = true,
  },
  dev = {
    path = "~/Projects",
    patterns = { "kanagawa-paper.nvim" },
    fallback = true, -- Fallback to git when local plugin doesn't exist
  },
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        -- "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
