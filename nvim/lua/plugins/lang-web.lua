-- local util = require("lspconfig.util")
--
-- local function get_typescript_plugin_path(root_dir)
--   local global_ts = "~/node_modules/@vue/typescript-plugin"
--   local found_ts = ""
--   local function check_dir(path)
--     found_ts = util.path.join(path, "node_modules", "@vue", "typescript-plugin")
--     if util.path.exists(found_ts) then
--       return path
--     end
--   end
--   if util.search_ancestors(root_dir, check_dir) then
--     print("using typescript plugin at " .. found_ts)
--     return found_ts
--   else
--     print("using global typescript plugin at " .. global_ts)
--     return global_ts
--   end
-- end
--
-- require("lspconfig").tsserver.setup({
--   init_options = {
--     plugins = {
--       {
--         name = "@vue/typescript-plugin",
--         location = get_typescript_plugin_path(vim.fn.getcwd()),
--         languages = { "javascript", "typescript", "vue" },
--       },
--     },
--   },
--   filetypes = {
--     "javascript",
--     "typescript",
--     "vue",
--   },
--   settings = {},
-- })

return {
  "vuki656/package-info.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  ft = { "json" },
  keys = {
    { "<localleader>nh", ":lua require('package-info').toggle()<CR>", desc = "Hide dependencies" },
    { "<localleader>nd", ":lua require('package-info').delete()<CR>", desc = "Delete dependency" },
    { "<localleader>nu", ":lua require('package-info').update()<CR>", desc = "Update dependency" },
    { "<localleader>nc", ":lua require('package-info').change_version()<CR>", desc = "Change version" },
    { "<localleader>ni", ":lua require('package-info').install()<CR>", desc = "Install new dependency" },
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
}
