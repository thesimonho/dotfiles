local util = require("lspconfig.util")

local function get_typescript_plugin_path(root_dir)
  local global_ts = "~/node_modules/@vue/typescript-plugin"
  local found_ts = ""
  local function check_dir(path)
    found_ts = util.path.join(path, "node_modules", "@vue", "typescript-plugin")
    if util.path.exists(found_ts) then
      return path
    end
  end
  if util.search_ancestors(root_dir, check_dir) then
    print("using typescript plugin at " .. found_ts)
    return found_ts
  else
    print("using global typescript plugin at " .. global_ts)
    return global_ts
  end
end

require("lspconfig").tsserver.setup({
  init_options = {
    plugins = {
      {
        name = "@vue/typescript-plugin",
        location = get_typescript_plugin_path(vim.fn.getcwd()),
        languages = { "javascript", "typescript", "vue" },
      },
    },
  },
  filetypes = {
    "javascript",
    "typescript",
    "vue",
  },
  settings = {},
})

return {}
